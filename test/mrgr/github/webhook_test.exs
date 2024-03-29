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

    test "creates a new PR", ctx do
      payload = read_webhook_data("pull_request", "opened")

      insert!(:repository, installation: ctx.installation, node_id: "R_kgDOGGc3xQ")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)
      assert pull_request.url == "https://github.com/crevalle/mrgr/pull/14"
      assert pull_request.ci_status == "success"
      assert Enum.count(pull_request.assignees) == 1
      assert Enum.count(pull_request.requested_reviewers) == 1
    end
  end

  describe "pull_request closed" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "changes the status of the PR", ctx do
      subscribe_to_installation(ctx.installation)

      payload = read_webhook_data("pull_request", "closed")
      {:ok, updated_pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      id = updated_pull_request.id

      assert updated_pull_request.status == "closed"
      assert Enum.count(Mrgr.PullRequest.for_installation(ctx.installation)) == 1
      assert Enum.count(Mrgr.PullRequest.pending_pull_requests(ctx.installation)) == 0

      assert_received(%{event: "pull_request:closed", payload: %Mrgr.Schema.PullRequest{id: ^id}})
    end
  end

  describe "pull_request reopened" do
    setup [:with_install_user, :with_installation]

    test "changes the status of the PR", ctx do
      # to test all the messages, don't create the pull_request in the setup block
      subscribe_to_installation(ctx.installation)

      insert!(:repository, installation: ctx.installation, node_id: "R_kgDOGGc3xQ")

      payload = read_webhook_data("pull_request", "opened")
      {:ok, _pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      payload = read_webhook_data("pull_request", "closed")
      {:ok, _pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      payload = read_webhook_data("pull_request", "reopened")
      {:ok, reopened} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assert reopened.status == "open"
      assert Enum.count(Mrgr.PullRequest.pending_pull_requests(ctx.installation)) == 1

      id = reopened.id

      assert_received(%{event: "pull_request:created", payload: %Mrgr.Schema.PullRequest{id: ^id}})

      assert_received(%{event: "pull_request:closed", payload: %Mrgr.Schema.PullRequest{id: ^id}})

      assert_received(%{
        event: "pull_request:reopened",
        payload: %Mrgr.Schema.PullRequest{id: ^id}
      })
    end
  end

  describe "pull_request_review_comment created" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "adds a comment to the PR" do
      payload = read_webhook_data("pull_request_review_comment", "created")

      {:ok, %{comments: [c]}} = Mrgr.Github.Webhook.handle("pull_request_review_comment", payload)

      assert c.object == :pull_request_review_comment
      assert c.raw
    end
  end

  describe "issue_comment created" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "adds a comment to the PR" do
      payload = read_webhook_data("issue_comment", "created")

      {:ok, %{comments: [c]}} = Mrgr.Github.Webhook.handle("issue_comment", payload)

      assert c.object == :issue_comment
      assert c.posted_at
      assert c.raw
    end
  end

  describe "pull_request_review:submitted" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "creates a pr_review for approved reviews" do
      payload = read_webhook_data("pull_request_review", "approved")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request_review", payload)

      review = hd(pull_request.pr_reviews)

      assert review.state == "approved"
    end

    test "creates a pr_review when changes are requested" do
      payload = read_webhook_data("pull_request_review", "changes_requested")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request_review", payload)

      review = hd(pull_request.pr_reviews)

      assert review.state == "changes_requested"
    end

    test "does NOT create a pr_review for commented reviews" do
      # this will overlook when you click Add Review -> comment btu who does that
      # "commented" comes in as a "submittted" action.  commented is the state
      payload = read_webhook_data("pull_request_review", "commented")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request_review", payload)

      assert pull_request.pr_reviews == []
    end
  end

  describe "pull_request_review:dismissed" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "changes the state of the review" do
      approved = read_webhook_data("pull_request_review", "approved")
      Mrgr.Github.Webhook.handle("pull_request_review", approved)

      dismissed = read_webhook_data("pull_request_review", "dismissed")
      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request_review", dismissed)

      review = hd(pull_request.pr_reviews)

      assert review.state == "dismissed"
    end
  end

  describe "pull_request:assigned" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "adds a user to the assignees list" do
      payload = read_webhook_data("pull_request", "assigned")
      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assignees = Enum.map(pull_request.assignees, & &1.login)

      assert assignees == ["crevalleghtest", "desmondmonster"]
    end

    test "does not duplicate users" do
      payload = read_webhook_data("pull_request", "assigned")

      Mrgr.Github.Webhook.handle("pull_request", payload)
      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assignees = Enum.map(pull_request.assignees, & &1.login)

      assert assignees == ["crevalleghtest", "desmondmonster"]
    end
  end

  describe "pull_request:unassigned" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "removes the user from the assignees list" do
      payload = read_webhook_data("pull_request", "unassigned")

      Mrgr.Github.Webhook.handle("pull_request", payload)
      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      assignees = Enum.map(pull_request.assignees, & &1.login)
      assert assignees == ["desmondmonster"]
    end
  end

  describe "pull_request:review_requested" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "adds a user from the list of requestees" do
      payload = read_webhook_data("pull_request", "review_requested")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      requested_reviewers = Enum.map(pull_request.requested_reviewers, & &1.login)

      assert requested_reviewers == ["crevalleghtest", "desmondmonster"]
    end
  end

  describe "pull_request:review_request_removed" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "removes a user from the list of requestees" do
      payload = read_webhook_data("pull_request", "review_request_removed")

      {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

      requested_reviewers = Enum.map(pull_request.requested_reviewers, & &1.login)
      assert requested_reviewers == ["desmondmonster"]
    end
  end

  describe "installation_repositories:added" do
    setup [:with_install_user, :with_installation]

    test "creates a repo associated with the installation", ctx do
      payload = read_webhook_data("installation_repositories", "added")

      # this wehbook returns a list of things added, why i don't know
      [{:ok, repository}] = Mrgr.Github.Webhook.handle("installation_repositories", payload)

      assert repository.name == "test-repo"
      assert repository.private
      assert repository.installation_id == ctx.installation.id
    end
  end

  describe "check_suite:requested" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "sets the ci status to 'running'" do
      payload = read_webhook_data("check_suite", "requested")

      [{:ok, pull_request}] = Mrgr.Github.Webhook.handle("check_suite", payload)

      assert pull_request.ci_status == "running"
    end
  end

  describe "check_suite:completed" do
    setup [:with_install_user, :with_installation, :with_open_pull_request]

    test "sets the ci status to 'success' on success" do
      payload = read_webhook_data("check_suite", "completed_success")

      [{:ok, pull_request}] = Mrgr.Github.Webhook.handle("check_suite", payload)

      assert pull_request.ci_status == "success"
    end

    test "sets the ci status to 'failure' on failure" do
      payload = read_webhook_data("check_suite", "completed_failure")

      [{:ok, pull_request}] = Mrgr.Github.Webhook.handle("check_suite", payload)

      assert pull_request.ci_status == "failure"
    end

    test "sets the ci status to 'failure' on an other status" do
      payload = read_webhook_data("check_suite", "completed_neutral")

      [{:ok, pull_request}] = Mrgr.Github.Webhook.handle("check_suite", payload)

      assert pull_request.ci_status == "failure"
    end
  end

  # a user signs up, then authorizes the app
  defp with_install_user(_ctx) do
    installer = insert!(:desmond)

    %{installer: installer}
  end

  defp with_installation(_ctx) do
    payload = read_webhook_data("installation", "created")

    {:ok, %Mrgr.Schema.Installation{} = installation} =
      Mrgr.Github.Webhook.handle("installation", payload)

    %{installation: installation}
  end

  defp with_open_pull_request(ctx) do
    # that special node_id mentioned in the PR webhook json
    repository = insert!(:repository, installation: ctx.installation, node_id: "R_kgDOGGc3xQ")

    payload = read_webhook_data("pull_request", "opened")
    {:ok, pull_request} = Mrgr.Github.Webhook.handle("pull_request", payload)

    %{repository: repository, pull_request: pull_request}
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
