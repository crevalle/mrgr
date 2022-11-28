defmodule Mrgr.Schema.FileChangeAlert do
  use Mrgr.Schema

  schema "file_change_alerts" do
    field(:name, :string)
    field(:color, :string, default: "#f1e5d1")
    field(:notify_user, :boolean)
    field(:pattern, :string)
    field(:source, Ecto.Enum, values: [:user, :system])

    belongs_to(:repository, Mrgr.Schema.Repository)
    timestamps()
  end

  @create_params [
    :color,
    :name,
    :notify_user,
    :pattern,
    :repository_id,
    :source
  ]

  @update_params [
    :color,
    :pattern,
    :name,
    :notify_user
  ]

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> validate_required(@create_params)
    |> strip_hashie_color_tag()
    |> foreign_key_constraint(:repository_id)
  end

  def update_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @update_params)
    |> validate_required(@update_params)
    |> strip_hashie_color_tag()
  end

  def strip_hashie_color_tag(changeset) do
    case get_change(changeset, :color) do
      color when is_bitstring(color) ->
        put_change(changeset, :color, String.replace(color, "#", ""))

      _ ->
        changeset
    end
  end
end
