defmodule Mrgr.Schema.Merge do
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

  schema "merges" do
    field(:external_id, :integer)
    field(:files_changed, {:array, :string})
    field(:head_commit, :map)
    field(:mergeable, :string)
    field(:merge_state_status, :string)
    field(:merge_queue_index, :integer)
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

    embeds_one(:user, Mrgr.Github.User, on_replace: :update)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    embeds_one(:merged_by, Mrgr.Github.User, on_replace: :update)
    field(:merged_at, :utc_datetime)

    has_one(:checklist, Mrgr.Schema.Checklist, on_delete: :delete_all)
    has_many(:checks, through: [:checklist, :checks])

    has_many(:comments, Mrgr.Schema.Comment)

    timestamps()
  end

  @create_fields ~w[
    mergeable
    merge_state_status
    merge_queue_index
    node_id
    number
    opened_at
    raw
    repository_id
    title
    url
  ]a

  @synchronize_fields ~w[
    mergeable
    merge_state_status
    title
  ]a

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
    |> validate_mergeable_fields()
    |> put_change(:raw, params)
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def commits_changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:commits)
  end

  def merge_queue_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:merge_queue_index])
  end

  def synchronize_changeset(schema, %{"pull_request" => params}) do
    schema
    |> cast(params, @synchronize_fields)
    |> cast_embed(:head)
    |> validate_mergeable_fields()
    |> put_change(:raw, params)
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

  # also upcases the strings
  def validate_mergeable_fields(changeset) do
    changeset
    |> validate_mergeable()
    |> validate_merge_state()
  end

  defp validate_mergeable(changeset) do
    case get_change(changeset, :mergeable) do
      empty when empty in [nil, ""] ->
        changeset

      change ->
        changeset
        |> put_change(:mergeable, String.upcase(change))
        |> validate_inclusion(:mergeable, @mergeable_states)
    end
  end

  defp validate_merge_state(changeset) do
    case get_change(changeset, :merge_state_status) do
      empty when empty in [nil, ""] ->
        changeset

      change ->
        changeset
        |> put_change(:merge_state_status, String.upcase(change))
        |> validate_inclusion(:merge_state_status, @merge_state_statuses)
    end
  end

  def external_merge_url(%{url: url}) when is_bitstring(url), do: url
  def external_merge_url(%{raw: %{"_links" => %{"html" => %{"href" => url}}}}), do: url
  def external_merge_url(_merge), do: ""

  def head_commit_message(%{head_commit: %{"commit" => %{"message" => message}}}), do: message
  def head_commit_message(_), do: "-"

  def head_committer(%{head_commit: %{"commit" => %{"committer" => %{"name" => name}}}}), do: name
  def head_committer(_), do: "-"

  def head_committed_at(%{head_commit: %{"commit" => %{"committer" => %{"date" => date}}}}) do
    {:ok, dt, _huh} = DateTime.from_iso8601(date)
    dt
  end

  def head_committed_at(_), do: nil

  def commit_message(%Mrgr.Github.Commit{commit: commit}) do
    commit.message
  end

  def author_name(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.name
  end

  def committed_at(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.date
  end

  def commit_sha(%Mrgr.Github.Commit{} = commit) do
    commit.sha
  end

  def mergeable_status(merge) do
    "#{merge.mergeable} #{merge.merge_state_status}"
  end
end
