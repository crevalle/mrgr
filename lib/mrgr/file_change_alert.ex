defmodule Mrgr.FileChangeAlert do
  alias Mrgr.Schema.FileChangeAlert, as: Schema
  alias Mrgr.FileChangeAlert.Query

  def for_repository(%{id: repo_id}) do
    Schema
    |> Query.for_repository(repo_id)
    |> Query.order_by_pattern()
    |> Mrgr.Repo.all()
  end

  defmodule Query do
    use Mrgr.Query

    def for_repository(query, repo_id) do
      from(q in query,
        where: q.repository_id == ^repo_id
      )
    end

    def order_by_pattern(query) do
      from(q in query,
        order_by: [desc: q.pattern]
      )
    end
  end
end
