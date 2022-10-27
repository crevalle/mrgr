defmodule Mrgr.Merge.Webhook do
  @moduledoc """

  Functions for handling incoming webhook params.
  """

  @typep webhook :: Mrgr.Gtihub.Webhook.t()
  @typep success :: {:ok, Mrgr.Merge.Schema.t()}
  @typep change_error :: {:error, Ecto.Changeset.t()}
  @typep not_found :: {:error, :not_found}

  @spec assign_user(webhook()) :: success() | change_error() | not_found()
  def assign_user(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.Merge.assign_user(merge, gh_user)
    end
  end

  @spec unassign_user(webhook()) :: success() | change_error() | not_found()
  def unassign_user(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.Merge.unassign_user(merge, gh_user)
    end
  end

  @spec add_reviewer(webhook()) :: success() | change_error() | not_found()
  def add_reviewer(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.Merge.add_reviewer(merge, gh_user)
    end
  end

  @spec remove_reviewer(webhook()) :: success() | change_error() | not_found()
  def remove_reviewer(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.Merge.remove_reviewer(merge, gh_user)
    end
  end

  @spec add_pr_review(webhook()) :: success() | change_error() | not_found()
  def add_pr_review(payload) do
    with {:ok, merge} <- find_merge(payload) do
      Mrgr.Merge.add_pr_review(merge, payload["review"])
    end
  end

  @spec find_merge(webhook() | map()) :: {:ok, Schema.t()} | not_found()
  defp find_merge(%{"node_id" => node_id}) do
    case Mrgr.Merge.find_by_node_id(node_id) do
      nil -> {:error, :not_found}
      merge -> {:ok, merge}
    end
  end

  defp find_merge(%{"pull_request" => params}) do
    find_merge(params)
  end
end
