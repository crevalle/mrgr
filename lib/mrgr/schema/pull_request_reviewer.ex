defmodule Mrgr.Schema.PullRequestReviewer do
  @moduledoc """
    join between PRs <> Members indicating they've been requested to review the PR
  """
  use Mrgr.Schema

  schema "pull_request_reviewers" do
    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    belongs_to(:member, Mrgr.Schema.Member)

    timestamps()
  end

  @fields [:pull_request_id, :member_id]

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:pull_request_id)
    |> foreign_key_constraint(:member_id)
    |> unique_constraint(@fields)
  end
end
