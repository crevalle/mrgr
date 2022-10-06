defmodule Mrgr.Github.WebhookTest do
  use Mrgr.DataCase

  describe "handle_webhook/2" do
    test "creates a webhook record" do
      headers = Map.put(sample_headers(), "x-github-event", "ein objecten")
      params = %{"action" => "did something"}

      Mrgr.Github.Webhook.handle_webhook(headers, params)

      hook = Mrgr.Repo.all(Mrgr.Schema.IncomingWebhook) |> List.first()

      assert hook.object == "ein objecten"
      assert hook.action == "did something"
      assert hook.data == params
      assert hook.source == "github"
      assert hook.headers == headers
    end
  end

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
      assert merge.merge_queue_index == 0
    end

    test "enqueues in the merge queue", ctx do
      subscribe_to_installation(ctx.installation)

      repo = build(:repository, installation: ctx.installation)
      first_merge = insert!(:merge, repository: repo, merge_queue_index: 0)

      payload = read_webhook_data("pull_request", "opened")
      {:ok, second_merge} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assert second_merge.node_id == "PR_kwDOGGc3xc4uUvfP"

      assert Mrgr.Merge.pending_merges(ctx.installation) |> Enum.map(& &1.id) == [
               first_merge.id,
               second_merge.id
             ]

      assert second_merge.merge_queue_index == 1

      # need to pull this out for matches to work
      id_2 = second_merge.id
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

  describe "pull_request_review_comment created" do
    setup [:with_install_user, :with_installation, :with_open_merge]

    test "adds a comment to the PR" do
      payload = read_webhook_data("pull_request_review_comment", "created")

      {:ok, comment} = Mrgr.Github.Webhook.handle("pull_request_review_comment", payload)

      assert comment.object == :pull_request_review_comment
      assert comment.raw
    end
  end

  describe "issue_comment created" do
    setup [:with_install_user, :with_installation, :with_open_merge]

    test "adds a comment to the PR" do
      payload = read_webhook_data("issue_comment", "created")

      {:ok, comment} = Mrgr.Github.Webhook.handle("issue_comment", payload)

      assert comment.object == :issue_comment
      assert comment.posted_at
      assert comment.raw
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

  defp sample_headers do
    %{
      "accept" => "*/*",
      "accept-encoding" => "gzip, deflate",
      "connect-time" => "0",
      "connection" => "close",
      "content-length" => "21161",
      "content-type" => "application/json",
      "host" => "smee.io",
      "timestamp" => "1633884050645",
      "total-route-time" => "0",
      "user-agent" => "GitHub-Hookshot/9b4b05d",
      "via" => "1.1 vegur",
      "x-forwarded-for" => "140.82.115.114",
      "x-forwarded-port" => "443",
      "x-forwarded-proto" => "https",
      "x-github-delivery" => "d388eb80-29e8-11ec-8c53-eeb8b1dc6d61",
      "x-github-event" => "pull_request",
      "x-github-hook-id" => "319629804",
      "x-github-hook-installation-target-id" => "139973",
      "x-github-hook-installation-target-type" => "integration",
      "x-request-id" => "9964a276-55dc-4e56-b6db-bf0fc58cea59",
      "x-request-start" => "1633884050644",
      "yo" => "momma"
    }
  end
end
