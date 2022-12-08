defmodule Mrgr.Github.Team do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:description, :string)
    field(:html_url, :string)
    field(:id, :integer)
    field(:members_url, :string)
    field(:name, :string)
    field(:node_id, :string)
    # i think this is a parent_id
    field(:parent, :integer)
    field(:permission, :string)
    field(:privacy, :string)
    field(:repositories_url, :string)
    field(:slug, :string)
    field(:url, :string)
  end

  @fields ~w[
    description
    html_url
    id
    members_url
    name
    node_id
    parent
    permission
    privacy
    repositories_url
    slug
    url
  ]a

  def new(nil), do: nil

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_changes()
  end

  def changeset(schema, params) do
    cast(schema, params, @fields)
  end
end
