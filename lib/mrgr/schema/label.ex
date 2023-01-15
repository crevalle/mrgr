defmodule Mrgr.Schema.Label do
  use Mrgr.Schema

  schema "labels" do
    field(:color, :string, default: "#f1e5d1")
    field(:description, :string)
    field(:name, :string)
    field(:repo_count, :integer, virtual: true)

    belongs_to(:installation, Mrgr.Schema.Installation)

    has_many(:label_repositories, Mrgr.Schema.LabelRepository,
      on_replace: :delete,
      on_delete: :delete_all
    )

    has_many(:repositories, through: [:label_repositories, :repository])

    has_many(:pr_labels, Mrgr.Schema.PullRequestLabel)
    has_many(:pull_requests, through: [:pr_labels, :pull_request])

    timestamps()
  end

  @allowed ~w[
    color
    description
    installation_id
    name
  ]a

  def create_changeset(schema, params) do
    schema
    |> changeset(params)
    |> cast_assoc(:label_repositories)
    |> add_hashie_tag_to_color()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> validate_required([:name, :color])
    |> add_hashie_tag_to_color()
    |> foreign_key_constraint(:installation_id)
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
