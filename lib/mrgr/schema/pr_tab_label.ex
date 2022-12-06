defmodule Mrgr.Schema.LabelPRTab do
  use Mrgr.Schema

  schema "label_pr_tabs" do
    field(:position, :integer)

    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:label, Mrgr.Schema.Label)

    timestamps()
  end

  @allowed ~w[
    label_id
    position
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
