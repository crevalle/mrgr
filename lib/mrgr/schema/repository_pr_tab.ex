defmodule Mrgr.Schema.RepositoryPRTab do
  use Mrgr.Schema

  schema "repository_pr_tabs" do
    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:pr_tab, Mrgr.Schema.PRTab)

    timestamps()
  end

  @allowed ~w[
    repository_id
    pr_tab_id
  ]a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @allowed)
    |> validate_required(@allowed)
  end
end
