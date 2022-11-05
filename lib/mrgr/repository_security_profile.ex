defmodule Mrgr.RepositorySecurityProfile do
  alias Mrgr.Schema.RepositorySecurityProfile, as: Schema
  alias __MODULE__.Query

  def for_installation(%Mrgr.Schema.Installation{id: id}), do: for_installation(id)

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Query.order(asc: :title)
    |> Mrgr.Repo.all()
  end

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
  end

  def update(schema, params) do
    schema
    |> Schema.changeset(params)
    |> Mrgr.Repo.update()
  end

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end
  end
end
