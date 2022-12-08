defmodule Mrgr.Schema.Team do
  use Mrgr.Schema

  schema "teams" do
    field(:description, :string)
    field(:external_id, :integer)
    field(:html_url, :string)
    field(:members_url, :string)
    field(:name, :string)
    field(:node_id, :string)
    field(:permission, :string)
    field(:privacy, :string)
    field(:repositories_url, :string)
    field(:slug, :string)
    field(:url, :string)

    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  @fields ~w[
    description
    external_id
    html_url
    installation_id
    members_url
    name
    node_id
    permission
    privacy
    repositories_url
    slug
    url
  ]a

  def create_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @fields)
    |> validate_required([:name, :installation_id])
    |> foreign_key_constraint(:installation_id)
  end
end
