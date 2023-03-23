defmodule Mrgr.Schema.ReviewerPRTab do
  use Mrgr.Schema

  schema "reviewer_pr_tabs" do
    belongs_to(:pr_tab, Mrgr.Schema.PRTab)
    belongs_to(:reviewer, Mrgr.Schema.Member)

    timestamps()
  end

  @allowed ~w[
    pr_tab_id
    member_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
