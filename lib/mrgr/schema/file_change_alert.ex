defmodule Mrgr.Schema.FileChangeAlert do
  use Mrgr.Schema

  schema "file_change_alerts" do
    field(:bg_color, :string, default: "#f1e5d1")
    field(:pattern, :string)
    field(:badge_text, :string)
    field(:notify_user, :boolean)

    belongs_to(:repository, Mrgr.Schema.Repository)
    timestamps()
  end

  @create_params [
    :bg_color,
    :pattern,
    :badge_text,
    :notify_user,
    :repository_id
  ]

  @update_params [
    :bg_color,
    :pattern,
    :badge_text,
    :notify_user
  ]

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> validate_required(@create_params)
    |> foreign_key_constraint(:repository_id)
  end

  def update_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @update_params)
    |> validate_required(@update_params)
  end
end
