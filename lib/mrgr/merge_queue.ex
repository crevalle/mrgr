defmodule Mrgr.MergeQueue do
  import Ecto.Query, only: [from: 2]

  @moduledoc """
  Something has to know "what's the list".  this module just takes whatever
  is given and assumes it's okay.  The onus is on the caller to pass in the correct
  and full list of pull requests.

  """

  def regenerate_pull_request_queue(installation) do
    installation
    |> Mrgr.PullRequest.pending_pull_requests()
    |> Enum.sort_by(& &1.opened_at, DateTime)
    |> regenerate_list_indices()
  end

  def clear_current_queue(pull_requests) do
    ids = Enum.map(pull_requests, & &1.id)

    # DOES NOT TOUCH updated_at.  assumes we'll set it shortly
    q = from(m in Mrgr.Schema.PullRequest, where: m.id in ^ids)
    Mrgr.Repo.update_all(q, set: [merge_queue_index: nil])
  end

  @spec enqueue([Mrgr.Schema.PullRequest.t()], Mrgr.Schema.PullRequest.t()) :: [
          Mrgr.Schema.PullRequest.t()
        ]
  def enqueue(list, pull_request) do
    # !!! avoids prepending and reversing the list because that adds too much mental
    # overhead, even though it is faster.  instead we use the simpler List.insert_at/2 and just keep the ordering intuitive by :merge_queue_order
    #
    # some assumptions this makes about the list:
    #
    # * queue has no gaps in :merge_queue_index attrs
    # * pull_request is not already in list
    # * this list is the correct list, eg, they do not belong to another user
    #
    # *** updates the items in place, ie, sets their indices

    updated = set_next_pull_request_queue_index(pull_request, list)

    List.insert_at(list, updated.merge_queue_index, updated)
  end

  def set_next_pull_request_queue_index(pull_request, list) do
    next = next_available_pull_request_queue_index(list)

    pull_request
    |> Mrgr.Schema.PullRequest.merge_queue_changeset(%{merge_queue_index: next})
    |> Mrgr.Repo.update!()
  end

  defp next_available_pull_request_queue_index([]), do: 0

  defp next_available_pull_request_queue_index(list) do
    max =
      list
      |> Enum.map(& &1.merge_queue_index)
      # wish we didn't need this vvv
      |> Enum.reject(&is_nil/1)
      |> Enum.max()

    max + 1
  end

  # returns the new list and the removed pull_request
  def remove(list, pull_request) do
    # unset this always.
    # a pull_request is marked "closed" before the list of pending pull requests is assembled, so it
    # is duly not included in the list.  we tolerate that here to give callers flexibility and assume
    # they know what they are doing
    updated_pull_request = unset_pull_request_index(pull_request)

    case Mrgr.List.find(list, pull_request) do
      %Mrgr.Schema.PullRequest{} = target ->
        # expects pull_request to still have its index, don't remove that until after
        # this operation
        updated_list =
          list
          |> remove_pull_request_from_list(target)
          |> regenerate_list_indices()

        {updated_list, updated_pull_request}

      nil ->
        {list, updated_pull_request}
    end
  end

  def unset_pull_request_index(pull_request) do
    pull_request
    |> Mrgr.Schema.PullRequest.merge_queue_changeset(%{merge_queue_index: nil})
    |> Mrgr.Repo.update!()
  end

  defp remove_pull_request_from_list(list, pull_request) do
    {_item, new_list} = List.pop_at(list, pull_request.merge_queue_index)
    new_list
  end

  defp regenerate_list_indices(list) do
    # most of the time people will pull_request from the front, requiring a wholesale redoing of
    # the list.  so let's just be naive and move on with our lives

    # this can issue a bunch of db calls if there are lots of PRs.
    # eventually put this all in a transaction
    list
    |> Enum.reduce([], fn m, acc ->
      enqueue(acc, m)
    end)
  end

  def update(list, pull_request, index) do
    list
    |> Enum.reject(fn m -> m.id == pull_request.id end)
    |> List.insert_at(index, pull_request)
    |> regenerate_list_indices()
  end
end
