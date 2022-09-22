defmodule Mrgr.Schema.ChecklistTemplate do
  use Mrgr.Schema

  schema "checklist_templates" do
    field(:title, :string)

    belongs_to(:installation, Mrgr.Schema.Installation)
    belongs_to(:creator, Mrgr.Schema.User)

    timestamps()
  end

  @create_params ~w[
    title
    installation_id
    creator_id
  ]a

  def create_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, @create_params)
    |> validate_required([:title])
    |> foreign_key_constraint(:installation_id)
    |> foreign_key_constraint(:creator_id)
  end
end
