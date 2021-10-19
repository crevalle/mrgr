defmodule Mrgr.Schema.Repository do
  use Mrgr.Schema

  schema "repositories" do
    field(:data, :map)
    field(:external_id, :integer)
    field(:full_name, :string)
    field(:name, :string)
    field(:node_id, :string)
    field(:private, :boolean)

    belongs_to(:installation, Mrgr.Schema.Installation)
    has_many(:members, through: [:installation, :member])
    has_many(:users, through: [:installation, :users])

    has_many(:merges, Mrgr.Schema.Merge)

    timestamps()
  end

  @allowed ~w[
    full_name
    name
    node_id
    private
    external_id
  ]a

  def changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> foreign_key_constraint(:installation_id)
    |> put_external_id()
    |> put_data_map()
  end

  def create_merges_changeset(schema, params) do
    schema
    |> Mrgr.Repo.preload(:merges)
    |> cast(params, [])
    |> cast_assoc(:merges, with: &Mrgr.Schema.Merge.create_changeset/2)
  end

  def owner_name(%{full_name: full_name}) do
    full_name
    |> String.split("/")
    |> List.to_tuple()
  end

  # %{
  #   "full_name" => "crevalle/node-cql-binary",
  #   "id" => 8829819,
  #   "name" => "node-cql-binary",
  #   "node_id" => "MDEwOlJlcG9zaXRvcnk4ODI5ODE5",
  #   "private" => false
  # },
end
