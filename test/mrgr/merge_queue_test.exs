defmodule Mrgr.MrgrQueueTest do
  # may not be async since we share db.
  # unless you use allowances, which i haven't figured out
  # how to use
  use ExUnit.Case, async: false

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Mrgr.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Mrgr.Repo, {:shared, self()})
  end

  import Mrgr.Factory

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
    test "removes a merge from the list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      [m1, m2] = list

      updated = Mrgr.MergeQueue.remove(list, m1)

      assert Enum.map(updated, & &1.id) == [m2.id]

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.Merge, m1.id)
      assert idx == nil
    end

    test "ignores when merge is not in list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      updated = Mrgr.MergeQueue.remove(list, insert!(:merge))

      assert updated == list
    end

    test "updates subsequent merge indices" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))
        |> Mrgr.MergeQueue.enqueue(insert!(:merge))

      [m1, m2] = list

      updated = Mrgr.MergeQueue.remove(list, m1)

      assert Enum.map(updated, & &1.id) == [m2.id]

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
