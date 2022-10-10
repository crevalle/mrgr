defmodule Mrgr.Merge.Webhook do
  @moduledoc """

  Functions for handling incoming webhook params.
  """

  @spec assign_user(Mrgr.Github.Webhook.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, Ecto.Changeset.t()}
  def assign_user(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.Merge.assign_user(merge, gh_user)
    end
  end

  @spec unassign_user(Mrgr.Github.Webhook.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, Ecto.Changeset.t()}
  def unassign_user(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["assignee"]) do
      Mrgr.Merge.unassign_user(merge, gh_user)
    end
  end

  @spec add_reviewer(Mrgr.Github.Webhook.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, Ecto.Changeset.t()}
  def add_reviewer(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.Merge.add_reviewer(merge, gh_user)
    end
  end

  @spec remove_reviewer(Mrgr.Github.Webhook.t()) ::
          {:ok, Mrgr.Schema.Merge.t()} | {:error, Ecto.Changeset.t()}
  def remove_reviewer(payload) do
    with {:ok, merge} <- find_merge(payload),
         gh_user <- Mrgr.Github.User.new(payload["requested_reviewer"]) do
      Mrgr.Merge.remove_reviewer(merge, gh_user)
    end
  end

  @spec find_merge(Mrgr.Github.Webhook.t() | map()) ::
          {:ok, Schema.t()} | {:error, :not_found}
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
