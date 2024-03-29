defmodule Mrgr.Schema.LabelPRTab do
  use Mrgr.Schema

  schema "label_pr_tabs" do
    belongs_to(:label, Mrgr.Schema.Label)
    belongs_to(:pr_tab, Mrgr.Schema.PRTab)

    timestamps()
  end

  @allowed ~w[
    label_id
    pr_tab_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
