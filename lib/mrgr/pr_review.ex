defmodule Mrgr.PRReview do
  alias Mrgr.Schema.PRReview, as: Schema
  alias __MODULE__.Query

  def find_for_pull_request(pull_request, node_id) do
    Schema
    |> Query.for_pull_request_id(pull_request.id)
    |> Query.by_node_id(node_id)
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def for_pull_request_id(query, id) do
      from(q in query,
        where: q.pull_request_id == ^id
      )
    end
  end
end
