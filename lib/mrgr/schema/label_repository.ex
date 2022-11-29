defmodule Mrgr.Schema.LabelRepository do
  use Mrgr.Schema

  schema "label_repositories" do
    field(:node_id, :string)

    belongs_to(:label, Mrgr.Schema.Label)
    belongs_to(:repository, Mrgr.Schema.Repository)

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:label_id, :repository_id, :node_id])
    |> foreign_key_constraint(:label_id)
    |> foreign_key_constraint(:repository_id)
  end
end
