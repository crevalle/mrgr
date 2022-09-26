defmodule Mrgr.Schema.ChecklistTemplate do
  use Mrgr.Schema

  schema "checklist_templates" do
    field(:title, :string)

    belongs_to(:installation, Mrgr.Schema.Installation)
    belongs_to(:creator, Mrgr.Schema.User)

    embeds_many(:check_templates, Mrgr.Schema.CheckTemplate, on_replace: :delete)

    timestamps()
  end

  @create_params ~w[
    title
  ]a

  def create_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> validate_required([:title])
    |> cast_embed(:check_templates, required: true)
    |> put_associations()
    |> foreign_key_constraint(:installation_id)
    |> foreign_key_constraint(:creator_id)
  end

  defp put_associations(changeset) do
    creator = changeset.params["creator"]
    installation = changeset.params["installation"]

    changeset
    |> put_assoc(:creator, creator)
    |> put_assoc(:installation, installation)
  end
end
