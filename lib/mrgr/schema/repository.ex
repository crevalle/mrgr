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
    |> put_external_id()
    |> put_data_map()
  end

  # %{
  #   "full_name" => "crevalle/node-cql-binary",
  #   "id" => 8829819,
  #   "name" => "node-cql-binary",
  #   "node_id" => "MDEwOlJlcG9zaXRvcnk4ODI5ODE5",
  #   "private" => false
  # },
end
