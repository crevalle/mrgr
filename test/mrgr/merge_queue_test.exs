defmodule Mrgr.MrgrQueueTest do
  # may not be async since we share db.
  # unless you use allowances, which i haven't figured out
  # how to use
  use Mrgr.DataCase

  describe "clear_current_queue/1" do
    setup [:with_installation, :with_repositories, :with_open_merges]

    test "clears out all merge indices", ctx do
      Mrgr.MergeQueue.clear_current_queue(ctx.merges)

      Enum.each(ctx.merges, fn m ->
        %{merge_queue_index: i} = Mrgr.Repo.get(Mrgr.Schema.Merge, m.id)
        assert i == nil
      end)
    end
  end

  describe "enqueue/2" do
    test "adds items to the end of the list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      assert Enum.map(list, & &1.merge_queue_index) == [0, 1, 2]
    end
  end

  describe "remove/2" do
    test "removes a merge from the list and unsets the queue index of the removed merge" do
      merge_1 = insert!(:merge)
      merge_2 = insert!(:merge)

      list =
        []
        |> Mrgr.MergeQueue.enqueue(merge_1)
        |> Mrgr.MergeQueue.enqueue(merge_2)

      # expects the passed-in merge to be current, ie, have the merge_queue_index set
      # otherwise the changeset to nilify it won't work
      # enqueuing updates the items
      [merge_1, _second] = list
      {[%{id: id}], removed} = Mrgr.MergeQueue.remove(list, merge_1)

      assert id == merge_2.id

      assert removed.id == merge_1.id
      assert removed.merge_queue_index == nil
      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, merge_1.id)
      assert idx == nil
    end

    test "ignores when merge is not in list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      {updated, _m} = Mrgr.MergeQueue.remove(list, insert!(:merge))

      assert updated == list
    end

    test "updates subsequent merge indices" do
      m1 = insert!(:merge)
      m2 = insert!(:merge)

      list =
        []
        |> Mrgr.MergeQueue.enqueue(m1)
        |> Mrgr.MergeQueue.enqueue(m2)

      # expects the passed-in merge to be current, ie, have the merge_queue_index set
      # otherwise the changeset to nilify it won't work
      [m1, _rest] = list
      {[updated], updated_merge} = Mrgr.MergeQueue.remove(list, m1)

      assert updated_merge.id == m1.id
      assert updated.id == m2.id

      assert updated_merge.merge_queue_index == nil

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m1.id)

      assert idx == nil

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m2.id)
      assert idx == 0
    end
  end

  describe "update_at/3" do
    test "inserts merge at the specified location and updates subsequent merges" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      [m1, m2, m3] = list

      updated = Mrgr.MergeQueue.update(list, m3, 0)

      assert Enum.map(updated, & &1.id) == [m3.id, m1.id, m2.id]

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m1.id)
      assert idx == 1

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m2.id)
      assert idx == 2

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m3.id)
      assert idx == 0
    end
  end

  defp with_installation(_ctx) do
    %{installation: insert!(:installation)}
  end

  defp with_repositories(%{installation: installation}, num \\ 3) do
    repos =
      Enum.reduce(0..num, [], fn _i, acc ->
        [insert!(:repository, installation_id: installation.id) | acc]
      end)

    %{repositories: repos}
  end

  defp with_open_merges(%{repositories: repositories}) do
    merges =
      repositories
      |> Enum.reduce([], fn r, acc ->
        idx = Enum.count(acc)
        merge = insert!(:merge, repository_id: r.id, merge_queue_index: idx)
        [merge | acc]
      end)

    %{merges: merges}
  end
end
