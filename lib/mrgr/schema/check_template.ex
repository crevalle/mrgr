defmodule Mrgr.Schema.CheckTemplate do
  use Mrgr.Schema

  embedded_schema do
    field(:text, :string)
    field(:type, Ecto.Enum, values: [:checkbox, :polar])
    field(:temp_id, :string, virtual: true)
  end

  @allowed ~w[
    text
    type
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
