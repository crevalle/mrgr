defmodule Mrgr.Repository do

  alias Mrgr.Repository.Query

  def find_by_name_for_user(user, name) do
    Mrgr.Schema.Repository
    |> Query.by_name(name)
    |> Query.for_user(user)
    |> Mrgr.Repo.one()
  end

  # gets and stores all for repos - client must be appropriate for repos
  # TODO repos need merges preloaded
  # TODO: pass in installation and fetch client from ets or db or something
  def fetch_and_store_open_merges!(repos, client) when is_list(repos) do
    repos
    |> Enum.map(fn r ->
      prs = fetch_open_merges(r, client)

      create_merges_from_data(r, prs)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp fetch_open_merges(repo, client) do
    open = %{state: "open"}

    {owner, name} = Mrgr.Schema.Repository.owner_name(repo)

    client
    |> Tentacat.Pulls.filter(owner, name, open)
    |> Mrgr.Github.parse()
    |> Mrgr.Github.write_json("test/response/repo/#{name}-prs.json")
  end

  defp create_merges_from_data(_repo, []), do: nil

  defp create_merges_from_data(repo, data) do
    repo
    |> Mrgr.Schema.Repository.create_merges_changeset(%{merges: data})
    |> Mrgr.Repo.update()
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
  end
end
