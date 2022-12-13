defmodule Mrgr.Schema.LabelPRTab do
  use Mrgr.Schema

  schema "label_pr_tabs" do
    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:label, Mrgr.Schema.Label)

    timestamps()
  end

  @allowed ~w[
    label_id
    user_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
