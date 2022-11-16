defmodule Mrgr.Repository do
  use Mrgr.PubSub.Event

  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

  def create(params) do
    with cs <- Schema.changeset(%Schema{}, params),
         {:ok, repository} <- Mrgr.Repo.insert(cs) do
      repository = set_and_apply_default_policy(repository)
      {:ok, repository}
    end
  end

  def find_by_name_for_user(user, name) do
    Schema
    |> Query.by_name(name)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  def for_user_with_policy(user) do
    Schema
    |> Query.for_user(user)
    |> Query.order(asc: :name)
    |> Query.with_policy()
    |> Mrgr.Repo.all()
    |> fix_case_sensitive_sort()
  end

  def for_user_with_rules(user) do
    Schema
    |> Query.for_user(user)
    |> Query.order(asc: :name)
    |> Query.with_alert_rules()
    |> Mrgr.Repo.all()
    |> fix_case_sensitive_sort()
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
    |> Query.order(asc: :name)
    |> Mrgr.Repo.paginate(page)
    |> fix_case_sensitive_sort()
  end

  def unset_policy_id(policy_id) do
    Schema
    |> Query.for_policy(policy_id)
    |> Query.set_settings_policy_id(nil)
    |> Mrgr.Repo.update_all([])
  end

  def set_and_apply_default_policy(repository) do
    default_policy = Mrgr.RepositorySettingsPolicy.default(repository.installation_id)

    case default_policy do
      nil ->
        repository

      policy ->
        repository
        |> Ecto.Changeset.change(%{repository_settings_policy_id: policy.id})
        |> Mrgr.Repo.update!()

        apply_policy_to_repo(repository, policy)
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

  # sql is always case sensitive.  i don't care about that here.
  defp fix_case_sensitive_sort(repos) do
    Enum.sort_by(repos, &String.downcase(&1.name))
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
  # check to see if we need to gather the rest
  def ensure_hydrated(%{language: nil} = repository) do
    data = fetch_repository_data(repository)

    repository
    |> Schema.changeset(data)
    |> Mrgr.Repo.update!()
    |> hydrate_ancillary_data()
  end

  def ensure_hydrated(repository), do: repository

  def fetch_repository_data(repository) do
    Mrgr.Github.API.fetch_repository(repository.installation, repository)
  end

  def hydrate_ancillary_data(repository) do
    repository
    |> generate_default_file_change_alerts()
    |> hydrate_branch_protection()
  end

  @spec generate_default_file_change_alerts(Schema.t()) :: Schema.t()
  def generate_default_file_change_alerts(%Schema{} = repository) do
    alerts =
      repository
      |> Mrgr.FileChangeAlert.defaults_for_repo()
      |> Enum.map(&Mrgr.FileChangeAlert.create/1)
      |> Enum.filter(fn {res, _alert} -> res == :ok end)
      |> Enum.map(&Mrgr.Tuple.take_value/1)

    %{repository | file_change_alerts: alerts}
  end

  @spec hydrate_branch_protection(Schema.t()) :: Schema.t()
  def hydrate_branch_protection(repository) do
    case fetch_branch_data(repository) do
      %{"required_pull_request_reviews" => attrs} ->
        repository
        |> Schema.branch_protection_changeset(attrs)
        |> Mrgr.Repo.update!()

      _branch_not_protected ->
        repository
    end
  end

  def fetch_branch_data(repository) do
    Mrgr.Github.API.fetch_branch_protection(repository)
  end

  def sync_all_settings_graphql(repository) do
    data =
      Mrgr.Github.API.fetch_repository_settings_graphql(repository)

    update_security_setting_data(repository, data)
  end

  # receives node list
  def refresh_all_security_settings(graphql_data) do
    # get all local repos at once, then look them up in memory
    # not all optimization is premature
    repos = fetch_local_repos(graphql_data)

    Enum.map(graphql_data, fn d ->
      case Map.get(repos, d["id"]) do
        # i guess
        nil ->
          nil

        repo ->
          update_security_setting_data(repo, d)
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def update_security_setting_data(repo, %{"node" => data}) do
    update_security_setting_data(repo, data)
  end

  def update_security_setting_data(repo, data) do
    # do this here cause that's when I have the data,
    # until I can do it somewhere else
    parent_params = %{parent: translate_parent_params(data["parent"])}

    repo =
      repo
      |> Schema.parent_changeset(parent_params)
      |> Mrgr.Repo.update!()

    params =
      %{settings: Mrgr.Schema.RepositorySettings.translate_graphql_params(data)}

    repo
    |> Schema.settings_changeset(params)
    |> Mrgr.Repo.update!()
  end

  def apply_policy_to_repo(repository, policy) do
    repository
    |> apply_merge_settings(policy)
    |> apply_branch_protection(policy)
    |> broadcast(@repository_updated)
  end

  def apply_merge_settings(repository, policy) do
    params =
      Mrgr.Schema.RepositorySettings.translate_names_to_rest_api(policy.settings)

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

  defp fetch_local_repos(graphql_data) do
    node_ids = Enum.map(graphql_data, & &1["id"])

    repos =
      Schema
      |> Query.by_node_ids(node_ids)
      |> Mrgr.Repo.all()

    # %{"<node_id>" => %Repository{}}
    Enum.reduce(repos, %{}, fn repo, acc ->
      Map.put(acc, repo.node_id, repo)
    end)
  end

  defp translate_parent_params(nil), do: %{}

  defp translate_parent_params(data) do
    %{node_id: data["id"], name: data["name"], name_with_owner: data["nameWithOwner"]}
  end

  @spec fetch_and_store_open_pull_requests!(Schema.t()) :: Schema.t()
  def fetch_and_store_open_pull_requests!(repo) do
    case fetch_open_pull_requests(repo) do
      [] ->
        repo

      pr_data ->
        repo
        |> create_pull_requests_from_data(pr_data)
        |> hydrate_pull_request_data()
    end
  end

  def fetch_open_pull_requests(repo) do
    result = Mrgr.Github.API.fetch_pulls_graphql(repo.installation, repo)

    result
    |> translate_graphql_attrs()
  end

  def translate_graphql_attrs(attrs) do
    attrs["repository"]["pullRequests"]["edges"]
    |> Enum.map(fn %{"node" => node} ->
      translate_node(node)
    end)
  end

  defp translate_node(node) do
    requested_reviewers =
      node["reviewRequests"]["nodes"]
      |> Enum.map(fn node -> node["requestedReviewer"] end)
      |> Enum.map(&Mrgr.Github.User.graphql_to_attrs/1)

    translated = %{
      "assignees" => Mrgr.Github.User.graphql_to_attrs(node["assignees"]["nodes"]),
      "created_at" => node["createdAt"],
      "head" => %{
        "node_id" => node["headRef"]["id"],
        "ref" => node["headRef"]["name"],
        "sha" => node["headRef"]["target"]["oid"]
      },
      "id" => node["databaseId"],
      "node_id" => node["id"],
      "requested_reviewers" => requested_reviewers,
      "url" => node["permalink"],
      "user" => %{
        "login" => node["author"]["login"],
        "avatar_url" => node["author"]["avatarUrl"]
      }
    }

    Map.merge(node, translated)
  end

  defp create_pull_requests_from_data(repo, data) do
    repo
    |> Schema.create_pull_requests_changeset(%{pull_requests: data})
    |> Mrgr.Repo.update!()
  end

  def hydrate_pull_request_data(repo) do
    pull_requests =
      repo.pull_requests
      # reverse preloading for API call
      |> Enum.map(fn m -> %{m | repository: repo} end)
      |> Enum.map(&Mrgr.PullRequest.hydrate_github_data/1)
      # fetch comments outside of `hydrate_github_data` since we only
      # need to hit the API when we're creating the world
      |> Enum.map(&Mrgr.PullRequest.sync_comments/1)

    %{repo | pull_requests: pull_requests}
  end

  # expects that you've preloaded it
  def has_policy?(%{policy: nil}), do: false
  def has_policy?(_repo), do: true

  # expects there to be a policy
  def settings_match_policy?(%{settings: settings, policy: %{settings: settings_policy}}) do
    Mrgr.Schema.RepositorySettings.match?(settings, settings_policy)
  end

  def apply_policy?(%{name: "postfactor"}), do: true
  def apply_policy?(%{name: "mother_brain"}), do: true
  def apply_policy?(%{name: "evidence_server"}), do: true
  def apply_policy?(%{name: "MoodTrackerClient"}), do: true
  def apply_policy?(%{name: "black-book-client"}), do: true
  def apply_policy?(_repo), do: false

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

    def with_alert_rules(query) do
      from(q in query,
        left_join: f in assoc(q, :file_change_alerts),
        preload: [file_change_alerts: f]
      )
    end
  end
end
