defmodule Mrgr.MergeQueue do
  import Ecto.Query, only: [from: 2]

  @moduledoc """
  Something has to know "what's the list".  this module just takes whatever
  is given and assumes it's okay.  The onus is on the caller to pass in the correct
  and full list of merges.

  """

  def regenerate_merge_queue(installation) do
    installation
    |> Mrgr.Merge.pending_merges()
    |> Enum.sort_by(& &1.opened_at, DateTime)
    |> regenerate_list_indices()
  end

  def clear_current_queue(merges) do
    ids = Enum.map(merges, & &1.id)

    # DOES NOT TOUCH updated_at.  assumes we'll set it shortly
    q = from(m in Mrgr.Schema.Merge, where: m.id in ^ids)
    Mrgr.Repo.update_all(q, set: [merge_queue_index: nil])
  end

  @spec enqueue([Mrgr.Schema.Merge.t()], Mrgr.Schema.Merge.t()) :: [Mrgr.Schema.Merge.t()]
  def enqueue(list, merge) do
    # !!! avoids prepending and reversing the list because that adds too much mental
    # overhead, even though it is faster.  instead we use the simpler List.insert_at/2
    # and just keep the ordering intuitive by :merge_queue_order
    #
    # some assumptions this makes about the list:
    #
    # * queue has no gaps in :merge_queue_index attrs
    # * merge is not already in list
    # * this list is the correct list, eg, they do not belong to another user

    updated = set_next_merge_queue_index(merge, list)

    List.insert_at(list, updated.merge_queue_index, updated)
  end

  def set_next_merge_queue_index(merge, list) do
    next = next_available_merge_queue_index(list)

    merge
    |> Mrgr.Schema.Merge.merge_queue_changeset(%{merge_queue_index: next})
    |> Mrgr.Repo.update!()
  end

  defp next_available_merge_queue_index([]), do: 1
  defp next_available_merge_queue_index(list) do
    Enum.max_by(list, & &1.merge_queue_index) + 1
  end

  def remove(list, merge) do
    case find_merge_by_id(list, merge.id) do
      %Mrgr.Schema.Merge{} = target ->
        # expects merge to still have its index, don't remove that until after
        # this operation
        updated =
          list
          |> remove_merge_from_list(target)
          |> regenerate_list_indices()

        unset_merge_index(target)

        updated

      nil ->
        list
    end
  end

  defp unset_merge_index(merge) do
    merge
    |> Mrgr.Schema.Merge.merge_queue_changeset(%{merge_queue_index: nil})
    |> Mrgr.Repo.update!()
  end

  defp remove_merge_from_list(list, merge) do
    {_item, new_list} = List.pop_at(list, merge.merge_queue_index)
    new_list
  end

  defp regenerate_list_indices(list) do
    # most of the time people will merge from the front, requiring a wholesale redoing of
    # the list.  so let's just be naive and move on with our lives

    # this can issue a bunch of db calls if there are lots of PRs.
    # eventually put this all in a transaction
    list
    |> Enum.reduce([], fn m, acc ->
      enqueue(acc, m)
    end)
  end

  def find_merge_by_id(merges, id) when is_integer(id) do
    Enum.find(merges, fn m -> m.id == id end)
  end

  def update(list, merge, index) do
    list
    |> Enum.reject(fn m -> m.id == merge.id end)
    |> List.insert_at(index, merge)
    |> regenerate_list_indices()
  end
end
