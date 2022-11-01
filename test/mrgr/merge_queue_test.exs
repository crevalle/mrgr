defmodule Mrgr.MrgrQueueTest do
  # may not be async since we share db.
  # unless you use allowances, which i haven't figured out
  # how to use
  use Mrgr.DataCase

  describe "clear_current_queue/1" do
    setup [:with_installation, :with_repositories, :with_open_pull_requests]

    test "clears out all merge indices", ctx do
      Mrgr.MergeQueue.clear_current_queue(ctx.pull_requests)

      Enum.each(ctx.pull_requests, fn m ->
        %{merge_queue_index: i} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m.id)
        assert i == nil
      end)
    end
  end

  describe "enqueue/2" do
    test "adds items to the end of the list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))

      assert Enum.map(list, & &1.merge_queue_index) == [0, 1, 2]
    end
  end

  describe "remove/2" do
    test "removes a pull_request from the list and unsets the queue index of the removed pull_request" do
      pull_request_1 = insert!(:pull_request)
      pull_request_2 = insert!(:pull_request)

      list =
        []
        |> Mrgr.MergeQueue.enqueue(pull_request_1)
        |> Mrgr.MergeQueue.enqueue(pull_request_2)

      # expects the passed-in pull_request to be current, ie, have the merge_queue_index set
      # otherwise the changeset to nilify it won't work
      # enqueuing updates the items
      [pull_request_1, _second] = list
      {[%{id: id}], removed} = Mrgr.MergeQueue.remove(list, pull_request_1)

      assert id == pull_request_2.id

      assert removed.id == pull_request_1.id
      assert removed.merge_queue_index == nil
      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, pull_request_1.id)
      assert idx == nil
    end

    test "ignores when pull_request is not in list" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))

      {updated, _m} = Mrgr.MergeQueue.remove(list, insert!(:pull_request))

      assert updated == list
    end

    test "updates subsequent pull_request indices" do
      m1 = insert!(:pull_request)
      m2 = insert!(:pull_request)

      list =
        []
        |> Mrgr.MergeQueue.enqueue(m1)
        |> Mrgr.MergeQueue.enqueue(m2)

      # expects the passed-in pull_request to be current, ie, have the merge_queue_index set
      # otherwise the changeset to nilify it won't work
      [m1, _rest] = list
      {[updated], updated_pull_request} = Mrgr.MergeQueue.remove(list, m1)

      assert updated_pull_request.id == m1.id
      assert updated.id == m2.id

      assert updated_pull_request.merge_queue_index == nil

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m1.id)

      assert idx == nil

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m2.id)
      assert idx == 0
    end
  end

  describe "update_at/3" do
    test "inserts pull request at the specified location and updates subsequent pull requests" do
      list =
        []
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))
        |> Mrgr.MergeQueue.enqueue(insert!(:pull_request))

      [m1, m2, m3] = list

      updated = Mrgr.MergeQueue.update(list, m3, 0)

      assert Enum.map(updated, & &1.id) == [m3.id, m1.id, m2.id]

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m1.id)
      assert idx == 1

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m2.id)
      assert idx == 2

      %{merge_queue_index: idx} = Mrgr.Repo.get(Mrgr.Schema.PullRequest, m3.id)
      assert idx == 0
    end
  end

  defp with_installation(_ctx) do
    %{installation: insert!(:installation)}
  end

  defp with_repositories(%{installation: installation}, num \\ 3) do
    repos =
      Enum.reduce(0..num, [], fn _i, acc ->
        [insert!(:repository, installation: installation) | acc]
      end)

    %{repositories: repos}
  end

  defp with_open_pull_requests(%{repositories: repositories}) do
    pull_request =
      repositories
      |> Enum.reduce([], fn r, acc ->
        idx = Enum.count(acc)
        pull_request = insert!(:pull_request, repository: r, merge_queue_index: idx)
        [pull_request | acc]
      end)

    %{pull_requests: pull_request}
  end
end
