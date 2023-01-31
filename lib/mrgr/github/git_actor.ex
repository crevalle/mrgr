defmodule Mrgr.Github.GitActor do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:avatar_url, :string)
    field(:date, :utc_datetime)
    field(:email, :string)
    field(:name, :string)
  end

  @allowed ~w[
    avatar_url
    date
    email
    name
  ]a

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_changes()
  end

  def changeset(schema, params) do
    params = fix_names(params)

    schema
    |> cast(params, @allowed)
  end

  def fix_names(params) do
    # string keys!
    params
    |> Map.put("avatar_url", params["avatarUrl"])
  end

  defmodule GraphQL do
    def attrs do
      """
      avatarUrl
      date
      email
      name
      """
    end
  end
end
