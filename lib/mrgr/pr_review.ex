defmodule Mrgr.PRReview do
  alias Mrgr.Schema.PRReview, as: Schema
  alias __MODULE__.Query

  def find_for_merge(merge, node_id) do
    Schema
    |> Query.for_merge_id(merge.id)
    |> Query.by_node_id(node_id)
    |> Mrgr.Repo.one()
  end

  defmodule Query do
    use Mrgr.Query

    def for_merge_id(query, id) do
      from(q in query,
        where: q.merge_id == ^id
      )
    end
  end
end
