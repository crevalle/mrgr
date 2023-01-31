defmodule Mrgr.Github.Commit do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:abbreviated_sha, :string)
    field(:additions, :integer)
    field(:deletions, :integer)
    field(:node_id, :string)
    field(:message, :string)
    field(:message_body, :string)
    field(:sha, :string)
    field(:status, :string)
    field(:url, :string)

    embeds_one(:author, Mrgr.Github.GitActor, on_replace: :update)
    embeds_one(:committer, Mrgr.Github.GitActor, on_replace: :update)
  end

  @allowed ~w[
    abbreviated_sha
    additions
    deletions
    node_id
    message
    message_body
    sha
    status
    url
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
    |> cast_embed(:author)
    |> cast_embed(:committer)
  end

  def fix_names(params) do
    params
    |> Map.put("abbreviated_sha", params["abbreviatedOid"])
    |> Map.put("node_id", params["id"])
    |> Map.put("message_body", params["messageBody"])
    |> Map.put("sha", params["oid"])
  end

  defmodule GraphQL do
    def full do
      """
      abbreviatedOid
      additions
      author {
        #{Mrgr.Github.User.GraphQL.git_actor()}
      }
      committer {
        #{Mrgr.Github.User.GraphQL.git_actor()}
      }
      deletions
      message
      messageBody
      oid
      id
      url
      status {
        state
      }
      """
    end

    def socks do
      """
      """
    end
  end
end
