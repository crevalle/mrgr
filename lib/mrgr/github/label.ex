defmodule Mrgr.Github.Label do
  use Mrgr.Schema
  alias __MODULE__.GraphQL

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

  def from_graphql(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&GraphQL.to_params/1)
    |> Enum.map(&new/1)
  end

  def from_graphql(_), do: []

  defmodule GraphQL do
    def to_params(nodes) when is_list(nodes) do
      Enum.map(nodes, &to_params/1)
    end

    def to_params(nil), do: []

    def to_params(node) do
      %{
        "color" => node["color"],
        "default" => node["isDefault"],
        "description" => node["description"],
        "name" => node["name"],
        "node_id" => node["id"],
        "url" => node["url"]
      }
    end

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
