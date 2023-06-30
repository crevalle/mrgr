defmodule Mrgr.Schema.PullRequest do
  use Mrgr.Schema

  @mergeable_states ["MERGEABLE", "CONFLICTING", "UNKNOWN"]
  @merge_state_statuses [
    "BEHIND",
    "BLOCKED",
    "CLEAN",
    "DIRTY",
    "DRAFT",
    "HAS_HOOKS",
    "UNKNOWN",
    "UNSTABLE"
  ]

  @ci_statuses [
    "success",
    "failure",
    "running"
  ]

  schema "pull_requests" do
    field(:additions, :integer)
    # counter cache, can update out from under us
    field(:approving_review_count, :integer)
    field(:ci_status, :string, default: "success")
    field(:controversial, :boolean)
    field(:deletions, :integer)
    field(:draft, :boolean)
    field(:external_id, :integer)
    field(:files_changed, {:array, :string})
    field(:head_commit, :map)
    field(:last_activity_at, :utc_datetime)
    field(:mergeable, :string)
    field(:merge_state_status, :string)
    field(:node_id, :string)
    field(:number, :integer)
    field(:opened_at, :utc_datetime)
    field(:raw, :map)
    field(:status, :string, default: "open")
    field(:title, :string)
    field(:url, :string)

    embeds_many(:commits, Mrgr.Github.Commit, on_replace: :delete)
    # what are assignees? how are they differetn from requested reviewers?
    embeds_many(:assignees, Mrgr.Github.User, on_replace: :delete)

    # TODO: these can be removed when I'm comfortable the new data is good.
    embeds_many(:requested_reviewers, Mrgr.Github.User, on_replace: :delete)

    # duplicate author info.
    # legacy PRs may have been opened by users who left
    # before Mrgr was installed, thus we don't have them as
    # members of the organization.  we don't care about finding
    # PRs by them, but we need to display their name somehow.
    # Also useful for when PRs are authored by bots, who are
    # not members of the org.  It's a current limitation of PR filtering
    # that we cannot filter PRs opened by bots.
    embeds_one(:user, Mrgr.Github.User, on_replace: :update)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    embeds_one(:merged_by, Mrgr.Github.User, on_replace: :update)
    field(:merged_at, :utc_datetime)

    has_many(:notifications_pull_requests, Mrgr.Schema.NotificationPullRequest)
    has_many(:notifications, through: [:notifications_pull_requests, :notification])

    has_many(:pr_labels, Mrgr.Schema.PullRequestLabel)
    has_many(:labels, through: [:pr_labels, :label])

    has_many(:comments, Mrgr.Schema.Comment, on_delete: :delete_all)

    # pr_reviews are the actual reviews and their reviewers
    has_many(:pr_reviews, Mrgr.Schema.PRReview, on_delete: :delete_all)

    # these vv are the people who were asked to review
    has_many(:pull_request_reviewers, Mrgr.Schema.PullRequestReviewer)
    has_many(:solicited_reviewers, through: [:pull_request_reviewers, :member])

    has_many(:high_impact_file_rule_pull_requests, Mrgr.Schema.HighImpactFileRulePullRequest)

    has_many(:high_impact_file_rules,
      through: [:high_impact_file_rule_pull_requests, :high_impact_file_rule]
    )

    has_many(:user_snoozed_pull_requests, Mrgr.Schema.UserSnoozedPullRequest)

    timestamps()
  end

  @create_fields ~w[
    additions
    author_id
    ci_status
    deletions
    draft
    files_changed
    mergeable
    merge_state_status
    merged_at
    node_id
    number
    opened_at
    raw
    repository_id
    status
    title
    url
  ]a

  @most_params ~w(
    additions
    deletions
    draft
    files_changed
    merge_state_status
    mergeable
    title
  )a

  def create_changeset(schema, params) do
    params = set_opened_at(params)

    schema
    |> cast(params, @create_fields)
    |> cast_embed(:user)
    |> cast_embed(:commits)
    |> cast_embed(:assignees)
    |> cast_embed(:head)
    |> put_external_id()
    |> put_change(:raw, params)
    |> put_timestamp(:last_activity_at)
    |> validate_inclusion(:ci_status, @ci_statuses)
    |> unique_constraint(:node_id)
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def ci_status_changeset(schema, params) do
    schema
    |> cast(params, [:ci_status])
    |> validate_inclusion(:ci_status, @ci_statuses)
  end

  def close_changeset(schema, %{"merged" => true} = params) do
    schema
    |> cast(params, [])
    |> cast_embed(:merged_by)
    |> put_merged_status()
    |> put_timestamp(:merged_at)
    |> put_timestamp(:last_activity_at)
  end

  def close_changeset(schema, %{"merged" => false} = params) do
    schema
    |> cast(params, [])
    |> put_closed_status()
    |> put_timestamp(:last_activity_at)
  end

  def change_assignees(schema, assignees) do
    schema
    |> change()
    |> put_embed(:assignees, assignees)
    |> put_timestamp(:last_activity_at)
  end

  def edit_changeset(schema, params) do
    schema
    |> cast(params, [:title])
    |> put_timestamp(:last_activity_at)
  end

  def most_changeset(schema, params) do
    schema
    |> cast(params, @most_params)
    |> cast_embed(:commits)
    |> put_timestamp(:last_activity_at)
    |> validate_inclusion(:mergeable, @mergeable_states)
    |> validate_inclusion(:merge_state_status, @merge_state_statuses)
  end

  def last_activity_changeset(schema) do
    schema
    |> change()
    |> put_timestamp(:last_activity_at)
  end

  def last_activity_changeset(schema, ts) do
    schema
    |> change()
    |> put_timestamp(:last_activity_at, ts)
  end

  def unstructify(struct) when is_struct(struct), do: Map.from_struct(struct)
  def unstructify(map) when is_map(map), do: map

  def put_closed_status(changeset) do
    put_change(changeset, :status, "closed")
  end

  def put_merged_status(changeset) do
    put_change(changeset, :status, "merged")
  end

  def set_opened_at(%{:created_at => at} = params) do
    Map.put(params, :opened_at, at)
  end

  def set_opened_at(%{"created_at" => at} = params) do
    Map.put(params, "opened_at", at)
  end

  def external_url(%{url: url}) when is_bitstring(url), do: url
  def external_url(%{raw: %{"_links" => %{"html" => %{"href" => url}}}}), do: url
  def external_url(_pull_request), do: ""

  def head(pull_request) do
    hd(pull_request.commits)
  end

  def branch_name(pull_request) do
    pull_request.raw["head"]["ref"]
  end

  def commit_message(%Mrgr.Github.Commit{} = commit) do
    commit.message
  end

  def commit_author_name(%Mrgr.Github.Commit{} = commit) do
    commit.author.name
  end

  def commit_sha(%Mrgr.Github.Commit{} = commit) do
    commit.sha
  end

  def required_approvals(pull_request) do
    pull_request.repository.settings.required_approving_review_count
  end

  def reviewer_requested?(%{solicited_reviewers: srs}, member) do
    srs
    |> Enum.map(& &1.id)
    |> Enum.member?(member.id)
  end

  def author_name(%{author: %{login: login}}), do: login
  def author_name(%{user: %{login: login}}), do: login
  def author_name(_), do: "unknown"

  def recent_comments(pull_request) do
    recently = Mrgr.DateTime.shift_from_now(-1, :day)

    pull_request.comments
    |> Enum.filter(&Mrgr.DateTime.after?(&1.posted_at, recently))
    |> Mrgr.Schema.Comment.rev_cron()
  end

  def latest_commit(%{commits: []}), do: nil

  def latest_commit(%{commits: commits}) do
    commits
    |> Enum.sort_by(& &1.author.date, {:desc, DateTime})
    |> hd()
  end

  def latest_commit_date(%{commits: []}), do: nil

  def latest_commit_date(%{commits: commits}) do
    commits
    |> Enum.sort_by(& &1.author.date, {:desc, DateTime})
    |> hd()
    |> Mrgr.DateTime.happened_at()
  end

  def latest_comment_date(%{comments: []}), do: nil

  def latest_comment_date(%{comments: comments}) do
    comments
    |> Mrgr.Schema.Comment.latest()
    |> Mrgr.DateTime.happened_at()
  end

  def latest_comment(%{comments: []}), do: nil

  def latest_comment(%{comments: comments}) do
    comments
    |> Mrgr.Schema.Comment.latest()
  end

  def latest_pr_review_date(%{pr_reviews: []}), do: nil

  def latest_pr_review_date(%{pr_reviews: pr_reviews}) do
    pr_reviews
    |> Mrgr.Schema.PRReview.latest()
    |> Mrgr.DateTime.happened_at()
  end

  def latest_pr_review(%{pr_reviews: []}), do: nil

  def latest_pr_review(%{pr_reviews: pr_reviews}) do
    pr_reviews
    |> Mrgr.Schema.PRReview.latest()
  end
end
