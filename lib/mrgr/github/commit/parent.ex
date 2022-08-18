defmodule Mrgr.Github.Commit.Parent do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:html_url, :string)
    field(:sha, :string)
    field(:url, :string)
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:html_url, :sha, :url])
  end
end
