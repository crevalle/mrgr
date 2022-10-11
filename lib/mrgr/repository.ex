defmodule Mrgr.Repository do
  alias Mrgr.Repository.Query
  alias Mrgr.Schema.Repository, as: Schema

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

  def toggle_merge_freeze(repo) do
    new_value = toggle(repo.merge_freeze_enabled)

    repo
    |> Schema.merge_freeze_changeset(%{merge_freeze_enabled: new_value})
    |> Mrgr.Repo.update!()
  end

  defp toggle(true), do: false
  defp toggle(false), do: true

  @spec fetch_and_store_open_merges!([Mrgr.Schema.Repository.t()]) :: [Mrgr.Schema.Merge.t()]
  def fetch_and_store_open_merges!(repos) when is_list(repos) do
    repos
    |> Enum.map(fn repo ->
      prs = fetch_open_merges(repo)

      create_merges_from_data(repo, prs)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&hydrate_merge_data/1)
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
