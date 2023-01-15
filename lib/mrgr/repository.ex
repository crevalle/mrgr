defmodule Mrgr.Repository do
  use Mrgr.PubSub.Event

  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

  def create(params) do
    with cs <- Schema.basic_changeset(%Schema{}, params),
         {:ok, repository} <- Mrgr.Repo.insert(cs) do
      repository
      |> sync_data()
      |> generate_default_high_impact_files()
      |> set_and_enforce_default_policy()
      |> Mrgr.Tuple.ok()
    end
  end

  def create_from_graphql(installation_params, node) do
    params =
      node
      |> node_to_params()
      |> Map.merge(installation_params)

    ### default policy is not applied here, it's done by caller
    # assuming that the installation is creating a bunch of these
    # and has that info

    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert!()
    |> generate_default_high_impact_files()
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
    |> Enum.map(&Mrgr.Github.Label.from_graphql/1)
    |> Enum.map(&Mrgr.Label.find_or_create_for_repo(&1, repo))
  end

  def update_labels_from_graphql(repo, _some_data), do: repo

  def find_by_name_for_user(user, name) do
    Schema
    |> Query.by_name(name)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  def for_user_with_policy(user) do
    Schema
    |> Query.for_user(user)
    |> Query.order_by_insensitive(asc: :name)
    |> Query.with_policy()
    |> Mrgr.Repo.all()
  end

  def for_user_with_rules(user) do
    Schema
    |> Query.for_user(user)
    |> Query.order_by_insensitive(asc: :name)
    |> Query.with_hif_rules()
    |> Mrgr.Repo.all()
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

  def for_installation(installation_id, page \\ []) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.paginate(page)
  end

  def all_for_installation(%{id: id}), do: all_for_installation(id)

  def all_for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order_by_insensitive(asc: :name)
    |> Mrgr.Repo.all()
  end

  def unset_policy_id(policy_id) do
    Schema
    |> Query.for_policy(policy_id)
    |> Query.set_settings_policy_id(nil)
    |> Mrgr.Repo.update_all([])
  end

  def set_policy(repository, policy) do
    repository
    |> Ecto.Changeset.change(%{repository_settings_policy_id: policy.id})
    |> Mrgr.Repo.update!()
  end

  def auto_enforce_policy(%{policy: %{enforce_automatically: true}} = repository) do
    enforce_repo_policy(repository)
  end

  def auto_enforce_policy(repository), do: repository

  def set_and_enforce_default_policy(repository) do
    default_policy = Mrgr.RepositorySettingsPolicy.default(repository.installation_id)

    case default_policy do
      nil ->
        repository

      policy ->
        repository
        |> set_policy(policy)
        |> enforce_repo_policy()
    end
  end

  def set_settings_policy_id(ids, installation_id, policy_id) do
    Schema
    |> Query.scoped_ids_for_installation(ids, installation_id)
    |> Query.set_settings_policy_id(policy_id)
    |> Mrgr.Repo.update_all([])
  end

  def id_counts_for_policies(policy_ids) do
    Enum.reduce(policy_ids, %{}, fn id, acc ->
      ids = ids_for_policy(id)
      Map.put(acc, id, ids)
    end)
  end

  def ids_for_policy(policy_id) do
    Schema
    |> Query.for_policy(policy_id)
    |> Query.select_ids()
    |> Mrgr.Repo.all()
  end

  def toggle_pull_request_freeze(repo) do
    new_value = toggle(repo.merge_freeze_enabled)

    repo
    |> Schema.merge_freeze_changeset(%{merge_freeze_enabled: new_value})
    |> Mrgr.Repo.update!()
  end

  defp toggle(true), do: false
  defp toggle(false), do: true

  # when we get a new repo hook it only has minimal data
  # because no code has been pushed. check to see if we need to gather the rest
  def sync_if_first_pr(%{language: nil} = repository) do
    repository
    |> sync_data()
    |> generate_default_high_impact_files()
  end

  def sync_if_first_pr(repository), do: repository

  def fetch_repository_data(repository) do
    Mrgr.Github.API.fetch_repository(repository.installation, repository)
  end

  @spec generate_default_high_impact_files(Schema.t()) :: Schema.t()
  def generate_default_high_impact_files(%Schema{} = repository) do
    hifs =
      repository
      |> Mrgr.HighImpactFile.defaults_for_repo()
      |> Enum.map(&Mrgr.HighImpactFile.create/1)
      |> Enum.filter(fn {res, _hif} -> res == :ok end)
      |> Enum.map(&Mrgr.Tuple.take_value/1)

    %{repository | high_impact_files: hifs}
  end

  def delete_all_for_installation(installation) do
    Schema
    |> Query.for_installation(installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&Mrgr.Repo.delete/1)
  end

  def enforce_repo_policy(%{policy: policy} = repository) do
    repository
    |> apply_merge_settings(policy)
    |> apply_branch_protection(policy)
    |> broadcast(@repository_updated)
  end

  def apply_merge_settings(repository, policy) do
    params = Mrgr.Schema.RepositorySettings.translate_names_to_rest_api(policy.settings)

    attrs =
      repository
      |> Mrgr.Github.API.update_repo_settings(params)
      |> Mrgr.Schema.RepositorySettings.translate_names_from_rest_api()

    repository
    |> Schema.settings_changeset(%{settings: attrs})
    |> Mrgr.Repo.update!()
  end

  def apply_branch_protection(repository, policy) do
    params =
      Mrgr.Schema.RepositorySettings.translate_branch_protection_to_rest_api(
        policy.settings,
        repository.settings
      )

    attrs =
      repository
      |> Mrgr.Github.API.update_branch_protection(params)
      |> Mrgr.Schema.RepositorySettings.translate_branch_protection_from_rest_api()

    repository
    |> Schema.settings_changeset(%{settings: attrs})
    |> Mrgr.Repo.update!()
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
        # i don't want to carry this info around on the repo since
        # it's only really used for analytics.  plus i don't need all
        # the extensive PR data for closed PRs.
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
        pull_requests =
          repo
          |> create_pull_requests_from_data(pr_data)
          # reverse preloading for API calls
          |> Enum.map(fn pr -> %{pr | repository: repo} end)
          # !!! this makes several API calls.  careful about scaling many onboarding users!
          |> Enum.map(&Mrgr.PullRequest.synchronize_for_creating_the_world/1)

        %{repo | pull_requests: pull_requests}
    end
  end

  def fetch_recently_closed_pull_requests(repo) do
    params = "last: 95, states: [MERGED], orderBy: {direction: DESC, field: CREATED_AT}"

    repo.installation
    |> Mrgr.Github.API.fetch_pulls_graphql(repo, params)
    |> parse_graphql_attrs()
  end

  def fetch_open_pull_requests(repo) do
    params = "last: 50, states: [OPEN]"

    repo.installation
    |> Mrgr.Github.API.fetch_pulls_graphql(repo, params)
    |> parse_graphql_attrs()
  end

  def parse_graphql_attrs(%{"repository" => %{"pullRequests" => %{"edges" => edges}}})
      when is_list(edges) do
    Enum.map(edges, fn %{"node" => node} -> parse_node(node) end)
  end

  # repo no longer exists?
  def parse_graphql_attrs(_), do: []

  defp parse_node(node) do
    requested_reviewers =
      node["reviewRequests"]["nodes"]
      |> Enum.map(fn node -> node["requestedReviewer"] end)
      |> Enum.map(&Mrgr.Github.User.graphql_to_attrs/1)

    author_id = find_member_id(node["author"]["id"])

    parsed = %{
      "author_id" => author_id,
      "assignees" => Mrgr.Github.User.graphql_to_attrs(node["assignees"]["nodes"]),
      "created_at" => node["createdAt"],
      "head" => %{
        "node_id" => node["headRef"]["id"],
        "ref" => node["headRef"]["name"],
        "sha" => node["headRef"]["target"]["oid"]
      },
      "id" => node["databaseId"],
      "merged_at" => node["mergedAt"],
      "node_id" => node["id"],
      "requested_reviewers" => requested_reviewers,
      "status" => String.downcase(node["state"]),
      "url" => node["permalink"],
      "user" => %{
        "login" => node["author"]["login"],
        "avatar_url" => node["author"]["avatarUrl"]
      }
    }

    Map.merge(node, parsed)
  end

  def find_member_id(nil), do: nil

  def find_member_id(node_id) do
    case Mrgr.Member.find_by_node_id(node_id) do
      %{id: id} -> id
      nil -> nil
    end
  end

  # will blow up if you try to do a duplicate
  def create_pull_requests_from_data(repo, data) do
    data
    |> Enum.map(&Map.put(&1, "repository_id", repo.id))
    |> Enum.map(&Mrgr.PullRequest.create_from_github_api_data/1)
  end

  # expects that you've preloaded it
  def has_policy?(%{policy: nil}), do: false
  def has_policy?(_repo), do: true

  # expects there to be a policy
  def settings_match_policy?(%{settings: settings, policy: %{settings: settings_policy}}) do
    Mrgr.Schema.RepositorySettings.match?(settings, settings_policy)
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

    def for_policy(query, id) do
      from(q in query,
        where: q.repository_settings_policy_id == ^id
      )
    end

    def set_settings_policy_id(query, id) do
      from(q in query,
        update: [set: [repository_settings_policy_id: ^id]]
      )
    end

    def select_ids(query) do
      from(q in query,
        select: q.id
      )
    end

    def with_policy(query) do
      from(q in query,
        left_join: p in assoc(q, :policy),
        preload: [policy: p]
      )
    end

    def with_hif_rules(query) do
      from(q in query,
        left_join: f in assoc(q, :high_impact_files),
        preload: [high_impact_files: f]
      )
    end
  end
end
