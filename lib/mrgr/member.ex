defmodule Mrgr.Member do
  alias Mrgr.Schema.Member, as: Schema
  alias __MODULE__.Query

  def paged_for_installation(installation_id, page \\ %{}) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(desc: :login)
    |> Mrgr.Repo.paginate(page)
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        join: i in assoc(q, :installations),
        where: i.id == ^installation_id
      )
    end
  end
end
