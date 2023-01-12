defmodule Mrgr.Schema.AuthorPRTab do
  use Mrgr.Schema

  schema "author_pr_tabs" do
    belongs_to(:pr_tab, Mrgr.Schema.PRTab)
    belongs_to(:author, Mrgr.Schema.Member)

    timestamps()
  end

  @allowed ~w[
    pr_tab_id
    author_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
