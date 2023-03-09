defmodule Mrgr.Schema.HighImpactFile do
  use Mrgr.Schema

  schema "high_impact_files" do
    field(:name, :string)
    field(:color, :string, default: "#f1e5d1")
    field(:notify_user, :boolean)
    field(:pattern, :string)
    field(:source, Ecto.Enum, values: [:user, :system])

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:user, Mrgr.Schema.User)

    has_many(:high_impact_file_pull_requests, Mrgr.Schema.HighImpactFilePullRequest)
    has_many(:pull_requests, through: [:high_impact_file_pull_requests, :pull_request])
    timestamps()
  end

  @create_params [
    :color,
    :name,
    :notify_user,
    :pattern,
    :repository_id,
    :source,
    :user_id
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
    |> add_hashie_tag_to_color()
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:user_id)
  end

  def update_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @update_params)
    |> validate_required(@update_params)
    |> add_hashie_tag_to_color()
  end

  def add_hashie_tag_to_color(changeset) do
    case get_change(changeset, :color) do
      color when is_bitstring(color) ->
        put_change(changeset, :color, add_hashie_tag(color))

      _ ->
        changeset
    end
  end

  defp add_hashie_tag("#" <> color), do: add_hashie_tag(color)
  defp add_hashie_tag(color), do: "##{color}"
end
