defmodule Mrgr.Github.Label do
  use Mrgr.Schema

  embedded_schema do
    field(:color, :string)
    field(:default, :boolean)
    field(:description, :string)
    field(:name, :string)
    field(:node_id, :string)
    field(:url, :string)
  end

  @attrs ~w(
    color
    default
    description
    name
    node_id
    url
  )a

  def new(nil), do: nil

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_changes()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
  end

  def from_graphql(labels) when is_list(labels) do
    Enum.map(labels, &from_graphql/1)
  end

  def from_graphql(label) do
    %{
      "color" => label["color"],
      "default" => label["isDefault"],
      "description" => label["description"],
      "name" => label["name"],
      "node_id" => label["id"],
      "url" => label["url"]
    }
  end

  defmodule GraphQL do
    def basic do
      """
        color
        description
        id
        isDefault
        name
        url
      """
    end
  end
end
