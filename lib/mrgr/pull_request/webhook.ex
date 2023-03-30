defmodule Mrgr.PullRequest.Webhook do
  @moduledoc """

  Functions for handling incoming webhook params.
  """

  @typep webhook :: Mrgr.Gtihub.Webhook.t()
  @typep success :: {:ok, Mrgr.PullRequest.Schema.t()}
  @typep change_error :: {:error, Ecto.Changeset.t()}
  @typep not_found :: {:error, :not_found}

  @spec ready_for_review(webhook()) :: success() | not_found()
  def ready_for_review(payload) do
    with {:ok, pull_request} <- find_pull_request(payload) do
      Mrgr.PullRequest.ready_for_review(pull_request)
    end
  end

  @spec converted_to_draft(webhook()) :: success() | not_found()
  def converted_to_draft(payload) do
    with {:ok, pull_request} <- find_pull_request(payload) do
      Mrgr.PullRequest.converted_to_draft(pull_request)
    end
  end

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
         %Mrgr.Github.User{} = gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]),
         %Mrgr.Schema.Member{} = member <- Mrgr.Member.find_from_github_user(gh_user) do
      Mrgr.PullRequest.add_reviewer(pull_request, member)
    end
  end

  def add_label(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         %Mrgr.Github.Label{} = label <- Mrgr.Github.Label.new(payload["label"]) do
      Mrgr.PullRequest.add_label(pull_request, label)
    end
  end

  def remove_label(payload) do
    with {:ok, pull_request} <- find_pull_request(payload),
         %Mrgr.Github.Label{} = label <- Mrgr.Github.Label.new(payload["label"]) do
      Mrgr.PullRequest.remove_label(pull_request, label)
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
         %Mrgr.Github.User{} = gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]),
         %Mrgr.Schema.Member{} = member <- Mrgr.Member.find_from_github_user(gh_user) do
      Mrgr.PullRequest.remove_reviewer(pull_request, member)
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

  @spec check_suite_requested(webhook()) :: [success() | change_error()]
  def check_suite_requested(%{"check_suite" => %{"pull_requests" => pull_request_data}}) do
    # comes in with a list of PRs, though how many there usually are, IDK
    pull_request_data
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.map(&Mrgr.PullRequest.find_by_external_id_with_repository/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Mrgr.PullRequest.set_ci_status_conclusion(&1, "running"))
  end

  @spec check_suite_completed(webhook()) :: [success() | change_error()]
  def check_suite_completed(%{"check_suite" => check_suite}) do
    pull_request_data = check_suite["pull_requests"]

    conclusion = check_suite["conclusion"]

    pull_request_data
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.map(&Mrgr.PullRequest.find_by_external_id_with_repository/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Mrgr.PullRequest.set_ci_status_conclusion(&1, conclusion))
  end

  @spec find_pull_request(webhook() | map()) :: {:ok, Schema.t()} | not_found()
  def find_pull_request(%{"node_id" => node_id}) do
    case Mrgr.PullRequest.find_for_webhook(node_id) do
      nil -> {:error, :not_found}
      pull_request -> {:ok, pull_request}
    end
  end

  def find_pull_request(%{"pull_request" => params}) do
    find_pull_request(params)
  end
end
