defmodule Mrgr.Schema.PRTab do
  use Mrgr.Schema

  schema "pr_tabs" do
    field(:title, :string)

    field(:meta, :map, default: %{}, virtual: true)
    field(:viewing_snoozed, :boolean, default: false, virtual: true)
    field(:snoozed, :string, virtual: true)
    field(:type, :string, virtual: true)

    field(:pull_requests, {:array, :map}, default: [], virtual: true)

    belongs_to(:user, Mrgr.Schema.User)

    timestamps()
  end

  @allowed ~w[
    title
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required([:user_id])
  end
end
