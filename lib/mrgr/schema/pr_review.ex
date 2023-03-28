defmodule Mrgr.Schema.PRReview do
  use Mrgr.Schema

  @states [
    "approved",
    "changes_requested",
    "commented",
    "dismissed",
    "pending"
  ]

  schema "pr_reviews" do
    field(:state, :string)
    field(:node_id, :string)
    field(:commit_id, :string)
    field(:submitted_at, :utc_datetime)
    field(:data, :map)

    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    embeds_one(:user, Mrgr.Github.User)

    timestamps()
  end

  @create_params ~w(
    commit_id
    data
    pull_request_id
    node_id
    state
    submitted_at
  )a

  def create_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> put_data_map()
    |> cast_embed(:user)
    |> validate_required(@create_params)
    |> validate_inclusion(:state, @states)
    |> foreign_key_constraint(:pull_request_id)
  end

  def dismiss_changeset(schema) do
    schema
    |> change(%{state: "dismissed"})
  end

  def cron(pr_reviews) do
    Enum.sort_by(pr_reviews, & &1.submitted_at, DateTime)
  end

  def rev_cron(pr_reviews) do
    Enum.sort_by(pr_reviews, & &1.submitted_at, {:desc, DateTime})
  end

  def latest(pr_reviews) do
    pr_reviews
    |> rev_cron()
    |> hd()
  end
end
