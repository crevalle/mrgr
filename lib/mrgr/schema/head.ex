defmodule Mrgr.Schema.Head do
  use Mrgr.Schema

  embedded_schema do
    field(:external_id, :integer)
    field(:ref, :string)
    field(:sha, :string)

    embeds_one(:user, Mrgr.Github.User, on_replace: :update)
    timestamps()
  end

  @fields ~w[
    sha
    ref
  ]a

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> cast_embed(:user)
    |> put_external_id()
  end
end
