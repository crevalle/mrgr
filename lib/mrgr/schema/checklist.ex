defmodule Mrgr.Schema.Checklist do
  use Mrgr.Schema

  schema "checklists" do
    field(:title, :string)

    belongs_to(:checklist_template, Mrgr.Schema.ChecklistTemplate)
    belongs_to(:merge, Mrgr.Schema.Merge)

    has_many(:checks, Mrgr.Schema.Check, on_delete: :delete_all)

    timestamps()
  end

  @create_params ~w[
    title
  ]a

  def create_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> validate_required([:title])
    |> put_associations()
    |> foreign_key_constraint(:checklist_template_id)
    |> foreign_key_constraint(:merge_id)
  end

  def put_associations(changeset) do
    template = changeset.params["checklist_template"]
    merge = changeset.params["merge"]
    checks = changeset.params["checks"]

    changeset
    |> put_assoc(:checklist_template, template)
    |> put_assoc(:merge, merge)
    |> put_assoc(:checks, checks)
  end
end
