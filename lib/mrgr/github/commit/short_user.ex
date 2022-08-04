defmodule Mrgr.Github.Commit.ShortUser do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:date, :utc_datetime)
    field(:email, :string)
    field(:name, :string)
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:date, :email, :name])
  end
end
