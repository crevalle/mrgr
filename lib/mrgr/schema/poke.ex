defmodule Mrgr.Schema.Poke do
  use Mrgr.Schema

  @types ["author", "reviewers"]

  @create_fields ~w(
    message
    node_id
    pull_request_id
    sender_id
    url
  )a

  schema "pokes" do
    field(:message, :string)
    field(:node_id, :string)
    field(:type, :string)
    field(:url, :string)

    belongs_to(:sender, Mrgr.Schema.User)
    belongs_to(:pull_request, Mrgr.Schema.PullRequest)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_fields)
    |> validate_required(@create_fields)
    |> validate_inclusion(:type, @types)
  end
end
