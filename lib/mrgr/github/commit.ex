defmodule Mrgr.Github.Commit do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:comments_url, :string)
    field(:html_url, :string)
    field(:node_id, :string)
    field(:sha, :string)
    field(:url, :string)

    embeds_one(:author, Mrgr.Github.User, on_replace: :update)
    embeds_one(:committer, Mrgr.Github.User, on_replace: :update)
    embeds_one(:commit, Mrgr.Github.Commit.Commit, on_replace: :update)
    embeds_many(:parents, Mrgr.Github.Commit.Parent, on_replace: :delete)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_changes()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:comments_url, :html_url, :node_id, :sha, :url])
    |> cast_embed(:author)
    |> cast_embed(:committer)
    |> cast_embed(:commit)
    |> cast_embed(:parents)
  end
end
