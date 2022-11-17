defmodule Mrgr.PullRequest.Webhook do
  @moduledoc """

  Functions for handling incoming webhook params.
  """

  @typep webhook :: Mrgr.Gtihub.Webhook.t()
  @typep success :: {:ok, Mrgr.PullRequest.Schema.t()}
  @typep change_error :: {:error, Ecto.Changeset.t()}
  @typep not_found :: {:error, :not_found}

  @spec assign_user(webhook()) :: success() | change_error() | not_found()
  def assign_user(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.PullRequest.assign_user(pull_request, gh_user)
    end
  end

  @spec unassign_user(webhook()) :: success() | change_error() | not_found()
  def unassign_user(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.PullRequest.unassign_user(pull_request, gh_user)
    end
  end

  @spec add_reviewer(webhook()) :: success() | change_error() | not_found()
  def add_reviewer(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         # TODO this can be a team
         %Mrgr.Github.User{} = gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.PullRequest.add_reviewer(pull_request, gh_user)
    end
  end

  # "requested_team" => %{
  # "description" => "Engineers who review infrastructure PRs",
  # "html_url" => "https://github.com/orgs/Shimmur/teams/infrastructure-reviewers",
  # "id" => 5028639,
  # "members_url" => "https://api.github.com/organizations/8060280/team/5028639/members{/member}",
  # "name" => "Infrastructure Reviewers",
  # "node_id" => "T_kwDOAHr9eM4ATLsf",
  # "parent" => %{
  # "description" => "Platform pod developers.",
  # "html_url" => "https://github.com/orgs/Shimmur/teams/platform-pod",
  # "id" => 3640092,
  # "members_url" => "https://api.github.com/organizations/8060280/team/3640092/members{/member}",
  # "name" => "Platform Pod",
  # "node_id" => "MDQ6VGVhbTM2NDAwOTI=",
  # "permission" => "pull",
  # "privacy" => "closed",
  # "repositories_url" => "https://api.github.com/organizations/8060280/team/3640092/repos",
  # "slug" => "platform-pod",
  # "url" => "https://api.github.com/organizations/8060280/team/3640092"
  # },

  @spec remove_reviewer(webhook()) :: success() | change_error() | not_found()
  def remove_reviewer(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         %Mrgr.Github.User{} = gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.PullRequest.remove_reviewer(pull_request, gh_user)
    end
  end

  @spec add_pr_review(webhook()) :: success() | change_error() | not_found()
  def add_pr_review(payload) do
    with {:ok, pull_request} <- find_pull_request(payload) do
      Mrgr.PullRequest.add_pr_review(pull_request, payload["review"])
    end
  end

  @spec dismiss_pr_review(webhook()) :: success() | change_error() | not_found()
  def dismiss_pr_review(payload) do
    with {:ok, pull_request} <- find_pull_request(payload) do
      Mrgr.PullRequest.dismiss_pr_review(pull_request, payload["review"]["node_id"])
    end
  end

  @spec find_pull_request(webhook() | map()) :: {:ok, Schema.t()} | not_found()
  defp find_pull_request(%{"node_id" => node_id}) do
    case Mrgr.PullRequest.find_by_node_id(node_id) do
      nil -> {:error, :not_found}
      pull_request -> {:ok, pull_request}
    end
  end

  defp find_pull_request(%{"pull_request" => params}) do
    find_pull_request(params)
  end
end