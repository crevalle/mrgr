defmodule Mrgr.Github.Repository do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:full_name, :string)
    field(:id, :integer)
    field(:name, :string)
    field(:node_id, :string)
    field(:private, :boolean)
  end

  # def new(params) do
  # keys =
  # %__MODULE__{}
  # |> Map.from_struct()
  # |> Map.keys()

  # %__MODULE__{}
  # |> cast(params, keys)
  # |> apply_changes()

  # params
  # end

  # field(:full_name" => "crevalle/mother_brain",
  # field(:id" => 66312740,
  # field(:name" => "mother_brain",
  # field(:node_id" => "MDEwOlJlcG9zaXRvcnk2NjMxMjc0MA==",
  # field(:private" => true
end
