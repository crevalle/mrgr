defmodule Mrgr.Schema.Comment do
  use Mrgr.Schema

  schema "comments" do
    field(:object, Ecto.Enum, values: [:issue_comment, :pull_request_review_comment])
    field(:posted_at, :utc_datetime)
    field(:raw, :map)

    belongs_to(:pull_request, Mrgr.Schema.PullRequest)

    timestamps()
  end

  def create_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:object, :raw, :pull_request_id, :posted_at])
    |> validate_required([:object, :posted_at])
    |> foreign_key_constraint(:pull_request_id)
  end

  def strip_bs(%{"comment" => comment_params}), do: %{"comment" => comment_params}
  def strip_bs(params), do: params

  # this may be wrong, a holdover from MVP
  def discussion_url(comment) do
    String.split(comment.raw["_links"]["html"]["href"], "discussion_") |> Enum.reverse() |> hd()
  end

  def author(%{raw: %{"comment" => %{"user" => user}}}) do
    Mrgr.Github.User.new(user)
  end

  def author(%{raw: %{"user" => user}}) do
    Mrgr.Github.User.new(user)
  end

  def author(%{raw: %{"author" => user}}) do
    Mrgr.Github.User.new(user)
  end

  def body(%{raw: %{"comment" => %{"body" => body}}}), do: body
  def body(%{raw: %{"body" => body}}), do: body

  def url(%{raw: %{"url" => url}}), do: url
  def url(%{raw: %{"comment" => %{"html_url" => url}}}), do: url
  def url(_), do: nil

  def cron(comments) do
    Enum.sort_by(comments, & &1.posted_at, DateTime)
  end

  def rev_cron(comments) do
    Enum.sort_by(comments, & &1.posted_at, {:desc, DateTime})
  end

  def latest(comments) do
    comments
    |> rev_cron()
    |> hd()
  end

  def review_id(%{raw: %{"pull_request_review_id" => id}}), do: id

  def initial_comment?(%{raw: %{"in_reply_to_id" => _external_id}}), do: false
  def initial_comment?(_comment), do: true

  def external_id(%{raw: %{"id" => id}}), do: id

  def in_reply_to_id(%{raw: %{"in_reply_to_id" => id}}), do: id
  def in_reply_to_id(_comment), do: nil

  def is_a_reply_to?(reply, parent) do
    in_reply_to_id(reply) == external_id(parent)
  end

  # raw: %{
  # "_links" => %{
  # "html" => %{
  # "href" => "https://github.com/crevalle/mrgr/pull/33#discussion_r986234822"
  # },
end
