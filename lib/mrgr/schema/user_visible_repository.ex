defmodule Mrgr.Schema.UserVisibleRepository do
  use Mrgr.Schema

  schema "user_visible_repositories" do
    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:repository, Mrgr.Schema.Repository)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:user_id, :repository_id])
    |> unique_constraint([:user_id, :repository_id])
  end
end
