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

  schema "pull_requests" do
    field(:external_id, :integer)
    field(:files_changed, {:array, :string})
    field(:head_commit, :map)
    field(:mergeable, :string)
    field(:merge_state_status, :string)
    field(:node_id, :string)
    field(:number, :integer)
    field(:opened_at, :utc_datetime)
    field(:raw, :map)
    field(:snoozed_until, :utc_datetime)
    field(:status, :string)
    field(:title, :string)
    field(:url, :string)

    embeds_many(:commits, Mrgr.Github.Commit, on_replace: :delete)
    embeds_many(:assignees, Mrgr.Github.User, on_replace: :delete)
    embeds_many(:requested_reviewers, Mrgr.Github.User, on_replace: :delete)

    # duplicate author info.
    # legacy PRs may have been opened by users who left
    # before Mrgr was installed, thus we don't have them as
    # members of the organization.  we don't care about finding
    # PRs by them, but we need to display their name somehow
    embeds_one(:user, Mrgr.Github.User, on_replace: :update)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    embeds_one(:merged_by, Mrgr.Github.User, on_replace: :update)
    field(:merged_at, :utc_datetime)

    has_one(:checklist, Mrgr.Schema.Checklist, on_delete: :delete_all)
    has_many(:checks, through: [:checklist, :checks])

    has_many(:pr_labels, Mrgr.Schema.PullRequestLabel)
    has_many(:labels, through: [:pr_labels, :label])

    has_many(:comments, Mrgr.Schema.Comment, on_delete: :delete_all)
    has_many(:pr_reviews, Mrgr.Schema.PRReview, on_delete: :delete_all)

    timestamps()
  end

  @create_fields ~w[
    author_id
    mergeable
    merge_state_status
    node_id
    number
    opened_at
    raw
    repository_id
    title
    url
  ]a

  @most_params ~w(
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
    |> cast_embed(:assignees)
    |> cast_embed(:requested_reviewers)
    |> cast_embed(:head)
    |> put_open_status()
    |> put_external_id()
    |> put_change(:raw, params)
    |> unique_constraint(:node_id)
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def commits_changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:commits)
  end

  def close_changeset(schema, %{"merged" => true} = params) do
    schema
    |> cast(params, [])
    |> cast_embed(:merged_by)
    |> put_closed_status()
    |> put_timestamp(:merged_at)
  end

  def close_changeset(schema, %{"merged" => false} = params) do
    schema
    |> cast(params, [])
    |> put_closed_status()
  end

  def change_assignees(schema, assignees) do
    schema
    |> change()
    |> put_embed(:assignees, assignees)
  end

  def change_reviewers(schema, reviewers) do
    schema
    |> change()
    |> put_embed(:requested_reviewers, reviewers)
  end

  def snooze_changeset(schema, ts) do
    schema
    |> change()
    |> put_timestamp(:snoozed_until, ts)
  end

  def edit_changeset(schema, params) do
    schema
    |> cast(params, [:title])
  end

  def most_changeset(schema, params) do
    schema
    |> cast(params, @most_params)
    |> validate_inclusion(:mergeable, @mergeable_states)
    |> validate_inclusion(:merge_state_status, @merge_state_statuses)
  end

  def unstructify(struct) when is_struct(struct), do: Map.from_struct(struct)
  def unstructify(map) when is_map(map), do: map

  def put_closed_status(changeset) do
    put_change(changeset, :status, "closed")
  end

  def put_open_status(changeset) do
    case get_change(changeset, :status) do
      empty when empty in [nil, ""] ->
        put_change(changeset, :status, "open")

      _status ->
        changeset
    end
  end

  def set_opened_at(%{:created_at => at} = params) do
    Map.put(params, :opened_at, at)
  end

  def set_opened_at(%{"created_at" => at} = params) do
    Map.put(params, "opened_at", at)
  end

  def external_pull_request_url(%{url: url}) when is_bitstring(url), do: url
  def external_pull_request_url(%{raw: %{"_links" => %{"html" => %{"href" => url}}}}), do: url
  def external_pull_request_url(_pull_request), do: ""

  def head(pull_request) do
    hd(pull_request.commits)
  end

  def branch_name(pull_request) do
    pull_request.raw["head"]["ref"]
  end

  def commit_message(%Mrgr.Github.Commit{commit: commit}) do
    commit.message
  end

  def commit_author_name(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.name
  end

  def committed_at(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.date
  end

  def commit_sha(%Mrgr.Github.Commit{} = commit) do
    commit.sha
  end

  def required_approvals(pull_request) do
    pull_request.repository.settings.required_approving_review_count
  end

  def author_name(%{author: %{login: login}}), do: login
  def author_name(%{user: %{login: login}}), do: login
  def author_name(_), do: "unknown"
end
