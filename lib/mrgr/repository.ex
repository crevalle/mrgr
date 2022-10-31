defmodule Mrgr.Repository do
  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
  end

  def find_by_name_for_user(user, name) do
    Schema
    |> Query.by_name(name)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  def for_user_with_rules(user) do
    Schema
    |> Query.for_user(user)
    |> Query.order(asc: :name)
    |> Query.with_alert_rules()
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

  def toggle_merge_freeze(repo) do
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

  @spec fetch_and_store_open_merges!(Schema.t()) :: Schema.t()
  def fetch_and_store_open_merges!(repo) do
    case fetch_open_merges(repo) do
      [] ->
        repo

      pr_data ->
        repo
        |> create_merges_from_data(pr_data)
        |> hydrate_merge_data()
    end
  end

  def fetch_open_merges(repo) do
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

  defp create_merges_from_data(repo, data) do
    repo
    |> Schema.create_merges_changeset(%{merges: data})
    |> Mrgr.Repo.update!()
  end

  def hydrate_merge_data(repo) do
    merges =
      repo.merges
      # reverse preloading for API call
      |> Enum.map(fn m -> %{m | repository: repo} end)
      |> Enum.map(&Mrgr.Merge.hydrate_github_data/1)
      # fetch comments outside of `hydrate_github_data` since we only
      # need to hit the API when we're creating the world
      |> Enum.map(&Mrgr.Merge.sync_comments/1)

    %{repo | merges: merges}
  end

  defmodule Query do
    use Mrgr.Query

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

    def with_alert_rules(query) do
      from(q in query,
        left_join: f in assoc(q, :file_change_alerts),
        preload: [file_change_alerts: f]
      )
    end

    def order(query, binding) do
      from(q in query,
        order_by: ^binding
      )
    end
  end
end
