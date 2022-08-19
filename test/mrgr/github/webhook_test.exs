defmodule Mrgr.Github.WebhookTest do
  use Mrgr.DataCase

  describe "installation created" do
    setup [:with_install_user]

    test "creates an installation" do
      payload = read_webhook_data("installation", "created")

      Mrgr.Github.Webhook.handle("installation", payload)

      assert Mrgr.Repo.get_by(Mrgr.Schema.Installation, external_id: 20_310_985)
    end
  end

  describe "pull_request opened" do
    setup [:with_install_user, :with_installation]

    test "creates a new PR" do
      payload = read_webhook_data("pull_request", "opened")

      {:ok, merge} = Mrgr.Github.Webhook.handle("pull_request", payload)
      assert merge.merge_queue_index == 1
    end

    test "enqueues in the merge queue", ctx do
      subscribe_to_installation(ctx.installation)

      payload = read_webhook_data("pull_request", "opened")
      {:ok, first_merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      payload = read_webhook_data("pull_request", "opened")
      {:ok, second_merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assert Mrgr.Merge.pending_merges(ctx.installation) |> Enum.map(& &1.id) == [
               first_merge.id,
               second_merge.id
             ]

      assert first_merge.merge_queue_index == 1
      assert second_merge.merge_queue_index == 2

      # need to pull this out for matches to work
      id_1 = first_merge.id
      id_2 = second_merge.id
      assert_received(%{event: "merge:created", payload: %Mrgr.Schema.Merge{id: ^id_1}})

      assert_received(%{event: "merge:created", payload: %Mrgr.Schema.Merge{id: ^id_2}})
    end
  end

  describe "pull_request closed" do
    setup [:with_install_user, :with_installation, :with_open_merge]

    test "changes the status of the PR", ctx do
      subscribe_to_installation(ctx.installation)

      payload = read_webhook_data("pull_request", "closed")
      {:ok, updated_merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      id = updated_merge.id

      assert updated_merge.status == "closed"
      assert Enum.count(Mrgr.Merge.merges(ctx.installation)) == 1
      assert Enum.count(Mrgr.Merge.pending_merges(ctx.installation)) == 0

      assert_received(%{event: "merge:closed", payload: %Mrgr.Schema.Merge{id: ^id}})
    end
  end

  describe "pull_request reopened" do
    setup [:with_install_user, :with_installation]

    test "changes the status of the PR", ctx do
      # to test all the messages, don't create the merge in the setup block
      subscribe_to_installation(ctx.installation)

      payload = read_webhook_data("pull_request", "opened")
      {:ok, _merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      payload = read_webhook_data("pull_request", "closed")
      {:ok, _merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      payload = read_webhook_data("pull_request", "reopened")
      {:ok, reopened} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assert reopened.status == "open"
      assert Enum.count(Mrgr.Merge.pending_merges(ctx.installation)) == 1

      id = reopened.id
      assert_received(%{event: "merge:created", payload: %Mrgr.Schema.Merge{id: ^id}})
      assert_received(%{event: "merge:closed", payload: %Mrgr.Schema.Merge{id: ^id}})
      assert_received(%{event: "merge:reopened", payload: %Mrgr.Schema.Merge{id: ^id}})
    end
  end

  # a user signs up, then authorizes the app
  defp with_install_user(_ctx) do
    installer = insert!(:desmond)

    %{installer: installer}
  end

  defp with_installation(_ctx) do
    payload = read_webhook_data("installation", "created")
    {:ok, installation} = Mrgr.Github.Webhook.handle("installation", payload)

    %{installation: installation}
  end

  defp with_open_merge(_ctx) do
    payload = read_webhook_data("pull_request", "opened")
    {:ok, merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

    %{merge: merge}
  end

  defp read_webhook_data(obj, action) do
    path = Path.join([File.cwd!(), "test", "webhook", obj, "#{action}.json"])

    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp subscribe_to_installation(installation) do
    topic = Mrgr.PubSub.Topic.installation(installation)
    Mrgr.PubSub.subscribe(topic)
  end
end
