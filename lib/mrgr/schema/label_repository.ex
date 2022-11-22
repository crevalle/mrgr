defmodule Mrgr.Schema.LabelRepository do
  use Mrgr.Schema

  schema "label_repositories" do
    belongs_to(:label, Mrgr.Schema.Label)
    belongs_to(:repository, Mrgr.Schema.Repository)

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:label_id, :repository_id])
    |> foreign_key_constraint(:label_id)
    |> foreign_key_constraint(:repository_id)
  end
end
