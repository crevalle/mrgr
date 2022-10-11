defmodule Mrgr.Schema.FileChangeAlert do
  use Mrgr.Schema

  schema "file_change_alerts" do
    field(:pattern, :string)
    field(:badge_text, :string)
    field(:notify_user, :boolean)

    belongs_to(:repository, Mrgr.Schema.Repository)
    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:pattern, :badge_text, :notify_user, :repository_id])
    |> validate_required([:pattern, :badge_text, :notify_user, :repository_id])
    |> foreign_key_constraint(:repository_id)
  end

  def update_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:pattern, :badge_text, :notify_user])
    |> validate_required([:pattern, :badge_text, :notify_user])
  end
end
