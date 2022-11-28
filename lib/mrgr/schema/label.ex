defmodule Mrgr.Schema.Label do
  use Mrgr.Schema

  schema "labels" do
    field(:color, :string, default: "#f1e5d1")
    field(:description, :string)
    field(:name, :string)

    field(:repository_count, :integer, virtual: true, default: 0)

    belongs_to(:installation, Mrgr.Schema.Installation)

    has_many(:label_repositories, Mrgr.Schema.LabelRepository, on_replace: :delete)
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
    |> cast(params, @allowed)
    |> validate_required([:name, :color])
    |> cast_assoc(:label_repositories)
    |> foreign_key_constraint(:installation_id)
  end
end
