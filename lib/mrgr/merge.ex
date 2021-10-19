defmodule Mrgr.Merge do
  alias Mrgr.Merge.Query

  def create(payload) do
    repository_id = payload["repository"]["id"]
    repo = Mrgr.Github.find(Mrgr.Schema.Repository, repository_id)

    user_id = payload["pull_request"]["user"]["id"]
    author = Mrgr.Github.find(Mrgr.Schema.Member, user_id)

    IO.inspect(repo, label: "repo")
    IO.inspect(author, label: "author")

    params =
      payload
      |> Map.get("pull_request")
      |> Map.put("repository_id", repo.id)
      |> Map.put("author_id", author.id)
      |> Map.put("opened_at", payload["pull_request"]["created_at"])

    Mrgr.Schema.Merge
    |> Mrgr.Schema.Merge.create_changeset(params)
    |> Mrgr.Repo.insert()
  end

  def pending_merges(%{current_installation_id: id}) do
    Mrgr.Schema.Merge
    |> Query.for_installation(id)
    |> Query.with_author()
    |> Query.open()
    |> Mrgr.Repo.all()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        join: r in assoc(q, :repository),
        join: i in assoc(r, :installation),
        where: i.id == ^installation_id,
        preload: [repository: r]
      )
    end

    def with_author(query) do
      from(q in query,
        left_join: a in assoc(q, :author),
        preload: [author: a]
      )
    end

    def open(query) do
      from(q in query,
        where: q.status == "open"
      )
    end
  end
end
