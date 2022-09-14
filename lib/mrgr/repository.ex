defmodule Mrgr.Repository do
  alias Mrgr.Repository.Query

  def find_by_name_for_user(user, name) do
    Mrgr.Schema.Repository
    |> Query.by_name(name)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  def for_user_with_rules(user) do
    Mrgr.Schema.Repository
    |> Query.for_user(user)
    |> Query.order(asc: :name)
    |> Query.with_alert_rules()
    |> Mrgr.Repo.all()
  end

  def toggle_merge_freeze(repo) do
    new_value = toggle(repo.merge_freeze_enabled)

    repo
    |> Mrgr.Schema.Repository.merge_freeze_changeset(%{merge_freeze_enabled: new_value})
    |> Mrgr.Repo.update!()
  end

  defp toggle(true), do: false
  defp toggle(false), do: true

  @spec fetch_and_store_open_merges!([Mrgr.Schema.Repository.t()], Mrgr.Schema.Installation.t()) ::
          [Mrgr.Schema.Merge.t()]
  def fetch_and_store_open_merges!(repos, installation) when is_list(repos) do
    repos
    |> Enum.map(fn repo ->
      prs = fetch_open_merges(repo, installation)

      create_merges_from_data(repo, prs)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&hydrate_merge_data(&1, installation))
  end

  defp fetch_open_merges(repo, installation) do
    opts = %{state: "open"}

    Mrgr.Github.API.fetch_filtered_pulls(installation, repo, opts)
  end

  defp create_merges_from_data(_repo, []), do: nil

  defp create_merges_from_data(repo, data) do
    repo
    |> Mrgr.Schema.Repository.create_merges_changeset(%{merges: data})
    |> Mrgr.Repo.update!()
  end

  def hydrate_merge_data(repo, installation) do
    Enum.map(repo.merges, fn merge ->
      # wish i didn't have to preload the repo here since i already
      # have it, but i didn't want to change all the github fetching
      # functions in the Merge module to accept the repo as a separate argument
      merge
      |> Mrgr.Repo.preload(:repository)
      |> Mrgr.Merge.hydrate_github_data(installation)
    end)
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
