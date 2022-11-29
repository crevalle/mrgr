defmodule Mrgr.Schema.Label do
  use Mrgr.Schema

  schema "labels" do
    field(:color, :string, default: "#f1e5d1")
    field(:description, :string)
    field(:name, :string)

    belongs_to(:installation, Mrgr.Schema.Installation)

    has_many(:label_repositories, Mrgr.Schema.LabelRepository, on_replace: :delete, on_delete: :delete_all)
    has_many(:repositories, through: [:label_repositories, :repository])

    timestamps()
  end

  @allowed ~w[
    color
    description
    installation_id
    name
  ]a

  def changeset(schema, params) do
    schema
    |> simple_changeset(params)
    |> cast_assoc(:label_repositories)
  end

  def simple_changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> validate_required([:name, :color])
    |> strip_hashie_color_tag()
    |> foreign_key_constraint(:installation_id)
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
