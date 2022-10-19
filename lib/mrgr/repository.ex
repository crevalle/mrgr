defmodule Mrgr.Repository do
  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

  @spec create_for_installation(Mrgr.Schema.Installation.t()) :: Mrgr.Schema.Installation.t()
  def create_for_installation(installation) do
    # assumes repos have been deleted
    repositories = fetch_repositories(installation)

    installation
    |> Mrgr.Schema.Installation.repositories_changeset(%{"repositories" => repositories})
    |> Mrgr.Repo.update!()
    |> generate_default_file_change_alerts()
  end

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
    |> generate_default_file_change_alerts()
  end

  def ensure_hydrated(repository), do: repository

  def fetch_repository_data(repository) do
    Mrgr.Github.API.fetch_repository(repository.installation, repository)
  end

  def generate_default_file_change_alerts(%Mrgr.Schema.Installation{} = installation) do
    # DOES NOT store generated FCAs on repos as preloads.  I don't think we need
    # that and I don't feel like building it now.  I'd need to unwrap the tuples
    # returned from create/1 and flat_map the whole thing or some shit.
    Enum.map(installation.repositories, &generate_default_file_change_alerts/1)

    installation
  end

  def generate_default_file_change_alerts(%Schema{} = repository) do
    repository
    |> Mrgr.FileChangeAlert.defaults_for_repo()
    |> Enum.map(&Mrgr.FileChangeAlert.create/1)
  end

  @spec fetch_and_store_open_merges!([Schema.t()]) :: [Mrgr.Schema.Merge.t()]
  def fetch_and_store_open_merges!(repos) when is_list(repos) do
    repos
    |> Enum.map(fn repo ->
      prs = fetch_open_merges(repo)

      create_merges_from_data(repo, prs)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&hydrate_merge_data/1)
  end

  def fetch_repositories(installation) do
    Mrgr.Github.API.fetch_repositories(installation)
  end

  defp fetch_open_merges(repo) do
    opts = %{state: "open"}

    Mrgr.Github.API.fetch_filtered_pulls(repo.installation, repo, opts)
  end

  defp create_merges_from_data(_repo, []), do: nil

  defp create_merges_from_data(repo, data) do
    repo
    |> Schema.create_merges_changeset(%{merges: data})
    |> Mrgr.Repo.update!()
  end

  def hydrate_merge_data(repo) do
    merges =
      repo.merges
      # reverse preloading
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
