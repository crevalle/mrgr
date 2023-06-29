defmodule Mrgr.Repository do
  use Mrgr.PubSub.Event

  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

  def create(params) do
    with cs <- Schema.basic_changeset(%Schema{}, params),
         {:ok, repository} <- Mrgr.Repo.insert(cs) do
      repository
      |> sync_data()
      |> generate_default_high_impact_file_rules()
      |> make_visible_to_all_users()
      |> Mrgr.Tuple.ok()
    end
  end

  def create_from_graphql(installation_params, node) do
    params =
      node
      |> node_to_params()
      |> Map.merge(installation_params)

    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert!()
    |> generate_default_high_impact_file_rules()
    |> make_visible_to_all_users()
  end

  def sync_data(repository) do
    data = Mrgr.Github.API.fetch_repository_data(repository)

    update_from_graphql(repository, data)
  end

  def node_to_params(attrs) do
    %{
      node_id: attrs["id"],
      private: attrs["isPrivate"],
      name: attrs["name"],
      language: parse_primary_language(attrs),
      parent: parse_parent_params(attrs["parent"]),
      settings: Mrgr.Schema.RepositorySettings.translate_graphql_params(attrs)
    }
  end

  defp parse_primary_language(%{"primaryLanguage" => %{"name" => name}}), do: name
  defp parse_primary_language(_), do: nil

  def update_from_graphql(repo, %{"node" => data}) do
    update_from_graphql(repo, data)
  end

  def update_from_graphql(repo, node) do
    update_labels_from_graphql(repo, node)

    params = node_to_params(node)

    repo
    |> Schema.changeset(params)
    |> Mrgr.Repo.update!()
  end

  def update_labels_from_graphql(repo, %{"labels" => %{"nodes" => nodes}}) do
    nodes
    |> Enum.map(&Mrgr.Github.Label.GraphQL.to_params/1)
    |> Enum.map(&Mrgr.Label.find_or_create_for_repo(&1, repo))

    repo
  end

  def update_labels_from_graphql(repo, _some_data), do: repo

  def for_user(user) do
    Schema
    |> Query.at_current_installation(user)
    |> Query.with_uvrs()
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def for_user_with_hif_rules(user) do
    # this will pull in hifs for repos at other installations,
    # but who cares
    grouped_hifs_by_repo =
      Mrgr.HighImpactFileRule.for_user(user)
      |> Enum.group_by(& &1.repository_id)

    Schema
    |> Query.at_current_installation(user)
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
    |> Enum.map(fn repo ->
      hifs = Map.get(grouped_hifs_by_repo, repo.id, [])

      %{repo | high_impact_file_rules: hifs}
    end)
  end

  def find_for_admin(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_installation()
    |> Query.with_all_hifs()
    |> Mrgr.Repo.one()
  end

  def find_for_user(user, ids) do
    Schema
    |> Query.for_user(user)
    |> Query.by_ids(ids)
    |> Mrgr.Repo.all()
  end

  def find_by_node_id(id) do
    Schema
    |> Query.by_node_id(id)
    |> Mrgr.Repo.one()
  end

  def find(id) do
    Schema
    |> Query.by_id(id)
    |> Mrgr.Repo.one()
  end

  def find_by_name(name) do
    Schema
    |> Mrgr.Repo.get_by(name: name)
  end

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_insensitive(asc: :name)
  end

  def all_for_installation(%{id: id}), do: all_for_installation(id)

  def all_for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def update_merge_freeze_status(repo, status) do
    repo
    |> Schema.merge_freeze_changeset(%{merge_freeze_enabled: status})
    |> Mrgr.Repo.update!()
    |> toggle_merge_freeze_on_github()
    |> Mrgr.PubSub.broadcast_to_installation(@repository_merge_freeze_status_changed)
  end

  def toggle_merge_freeze_on_github(repo) do
    # turns out we haven't built this yet, but i think we're close?
    # see Mrgr.CheckRun.create()

    repo
  end

  # when we get a new repo hook it only has minimal data
  # because no code has been pushed. check to see if we need to gather the rest
  def sync_if_first_pr(%{language: nil} = repository) do
    repository
    |> sync_data()
    |> generate_default_high_impact_file_rules()
  end

  def sync_if_first_pr(repository), do: repository

  def fetch_repository_data(repository) do
    Mrgr.Github.API.fetch_repository(repository.installation, repository)
  end

  @spec generate_default_high_impact_file_rules(Schema.t()) :: Schema.t()
  def generate_default_high_impact_file_rules(%Schema{} = repository) do
    users = Mrgr.User.for_installation(repository.installation_id)

    rules =
      users
      |> Enum.map(&Mrgr.HighImpactFileRule.create_user_defaults_for_repository(&1, repository))
      |> List.flatten()
      |> Enum.filter(fn {res, _hif} -> res == :ok end)
      |> Enum.map(&Mrgr.Tuple.take_value/1)

    %{repository | high_impact_file_rules: rules}
  end

  def make_visible_to_all_users(repository) do
    repository.installation_id
    |> Mrgr.User.for_installation()
    |> Enum.map(&make_repo_visible_to_user(repository, &1))

    repository
  end

  def make_repo_visible_to_user(repo, user) do
    # expects it not to exist.  also that the user has access to the repo
    params = %{user_id: user.id, repository_id: repo.id}

    %Mrgr.Schema.UserVisibleRepository{}
    |> Mrgr.Schema.UserVisibleRepository.changeset(params)
    |> Mrgr.Repo.insert!()

    Mrgr.PubSub.broadcast_to_installation(repo, @repository_visibility_updated)
  end

  def hide_repo_from_user(user, repo) do
    with %Mrgr.Schema.UserVisibleRepository{} = v <- find_uvr(repo, user) do
      Mrgr.Repo.delete(v)
      Mrgr.PubSub.broadcast_to_installation(repo, @repository_visibility_updated)
      repo
    end
  end

  def find_uvr(repo, user) do
    Mrgr.Repo.one(Query.uvr(repo, user))
  end

  def delete_all_for_installation(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&Mrgr.Repo.delete/1)
  end

  defp parse_parent_params(nil), do: %{}

  defp parse_parent_params(data) do
    %{node_id: data["id"], name: data["name"], name_with_owner: data["nameWithOwner"]}
  end

  def sync_recentish_closed_pull_requests(repo) do
    case fetch_recently_closed_pull_requests(repo) do
      [] ->
        repo

      pr_data ->
        _prs = create_pull_requests_from_data(repo, pr_data)
        repo
    end
  end

  @spec sync_open_pull_requests(Schema.t()) :: Schema.t()
  def sync_open_pull_requests(repo) do
    case fetch_open_pull_requests(repo) do
      [] ->
        repo

      pr_data ->
        repo = Mrgr.Repo.preload(repo, :high_impact_file_rules)

        pull_requests =
          repo
          |> create_pull_requests_from_data(pr_data)
          |> Enum.map(fn pr -> %{pr | repository: repo} end)
          |> Enum.map(&Mrgr.PullRequest.create_rest_of_world/1)
          |> Enum.map(&Mrgr.HighImpactFileRule.reset(repo, &1))

        %{repo | pull_requests: pull_requests}
    end
  end

  def fetch_recently_closed_pull_requests(repo) do
    params = "last: 95, states: [MERGED], orderBy: {direction: DESC, field: CREATED_AT}"

    repo
    |> Mrgr.Github.API.fetch_heavy_pulls(params)
    |> parse_graphql_attrs()
  end

  def fetch_open_pull_requests(repo) do
    params = "last: 50, states: [OPEN]"

    repo
    |> Mrgr.Github.API.fetch_heavy_pulls(params)
    |> parse_graphql_attrs()
  end

  def parse_graphql_attrs(%{"repository" => %{"pullRequests" => %{"edges" => edges}}})
      when is_list(edges) do
    Enum.map(edges, fn %{"node" => node} ->
      Mrgr.Github.PullRequest.GraphQL.heavy_pull_to_params(node)
    end)
  end

  # repo no longer exists?
  def parse_graphql_attrs(_), do: []

  # will blow up if you try to do a duplicate
  def create_pull_requests_from_data(repo, data) do
    data
    |> Enum.map(fn params ->
      params
      |> Map.put("repository_id", repo.id)
      |> Map.put("installation_id", repo.installation_id)
    end)
    |> Enum.map(&Mrgr.PullRequest.create_for_onboarding/1)
  end

  def broadcast(repository, event) do
    topic = Mrgr.PubSub.Topic.installation(repository)
    Mrgr.PubSub.broadcast(repository, topic, event)

    repository
  end

  defmodule Query do
    use Mrgr.Query

    def scoped_ids_for_installation(query, ids, installation_id) do
      query
      |> by_ids(ids)
      |> for_installation(installation_id)
    end

    def by_name(query, name) do
      from(q in query,
        where: q.name == ^name
      )
    end

    def at_current_installation(query, %{current_installation_id: id}) do
      for_installation(query, id)
    end

    def for_user(query, %{id: user_id}) do
      from(q in query,
        inner_join: u in assoc(q, :users),
        where: u.id == ^user_id
      )
    end

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end

    def with_installation(query) do
      from(q in query,
        join: i in assoc(q, :installation),
        join: a in assoc(i, :account),
        preload: [installation: {i, account: a}]
      )
    end

    def with_all_hifs(query) do
      from(q in query,
        preload: [high_impact_file_rules: :user]
      )
    end

    # !!! NOT scoped to a user.  all of them
    def with_uvrs(query) do
      from(q in query,
        left_join: uvrs in assoc(q, :user_visible_repositories),
        preload: [user_visible_repositories: uvrs]
      )
    end

    def select_ids(query) do
      from(q in query,
        select: q.id
      )
    end

    def uvr(user, repo) do
      from(q in Mrgr.Schema.UserVisibleRepository,
        where: q.user_id == ^user.id,
        where: q.repository_id == ^repo.id
      )
    end
  end
end
