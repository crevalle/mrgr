defmodule Mrgr.Team do
  alias Mrgr.Schema.Team, as: Schema
  alias __MODULE__.Query

  def find_by_node_id(node_id) do
    Schema
    |> Query.by_node_id(node_id)
    |> Mrgr.Repo.one()
  end

  def for_installation(%Mrgr.Schema.Installation{id: id}), do: for_installation(id)

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(asc: :name)
    |> Mrgr.Repo.all()
  end

  def create!(attrs) do
    %Schema{}
    |> Schema.create_changeset(attrs)
    |> Mrgr.Repo.insert!()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, installation_id) do
      from(q in query,
        where: q.installation_id == ^installation_id
      )
    end
  end
end
