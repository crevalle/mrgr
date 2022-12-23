defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  @type t :: map()

  def handle_webhook(headers, params) do
    obj = headers["x-github-event"]
    action = params["action"]
    IO.inspect("*** RECEIVED WEBHOOK: #{obj}:#{action}")

    {:ok, hook} = create_incoming_webhook_record(obj, action, headers, params)

    enqueue_webhook_handling(hook)

    hook
  end

  def enqueue_webhook_handling(hook) do
    %{id: hook.id}
    |> Mrgr.Worker.Webhook.new()
    |> Oban.insert()
  end

  ### HANDLER IMPLEMENTATIONS
  #
  #
  ### add new handlers below vvvv

  def handle("installation", %{"action" => "created"} = payload) do
    Mrgr.Installation.create_from_webhook(payload)
  end

  def handle("installation", %{"action" => "deleted"} = payload) do
    Mrgr.Installation.delete_from_webhook(payload)
  end

  def handle("installation_repositories", %{"action" => "added"} = payload) do
    Mrgr.Repository.Webhook.create(payload)
  end

  def handle("pull_request", %{"action" => "opened"} = payload) do
    Mrgr.PullRequest.create_from_webhook(payload)
  end

  def handle("pull_request", %{"action" => "reopened"} = payload) do
    Mrgr.PullRequest.reopen(payload)
  end

  def handle("pull_request", %{"action" => "edited"} = payload) do
    Mrgr.PullRequest.edit(payload)
  end

  def handle("pull_request", %{"action" => "closed"} = payload) do
    Mrgr.PullRequest.close(payload)
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def handle("pull_request", %{"action" => "synchronize"} = payload) do
    Mrgr.PullRequest.synchronize(payload)
    # Mrgr.CheckRun.create(payload)
  end

  def handle("pull_request", %{"action" => "assigned"} = payload) do
    Mrgr.PullRequest.Webhook.assign_user(payload)
  end

  def handle("pull_request", %{"action" => "unassigned"} = payload) do
    Mrgr.PullRequest.Webhook.unassign_user(payload)
  end

  def handle("pull_request", %{"action" => "review_requested"} = payload) do
    Mrgr.PullRequest.Webhook.add_reviewer(payload)
  end

  def handle("pull_request", %{"action" => "review_request_removed"} = payload) do
    Mrgr.PullRequest.Webhook.remove_reviewer(payload)
  end

  def handle("pull_request", %{"action" => "labeled"} = payload) do
    Mrgr.PullRequest.Webhook.add_label(payload)
  end

  def handle("pull_request", %{"action" => "unlabeled"} = payload) do
    Mrgr.PullRequest.Webhook.remove_label(payload)
  end

  def handle("label", %{"action" => "created"} = payload) do
    Mrgr.Label.Webhook.create(payload)
  end

  def handle("label", %{"action" => "edited"} = payload) do
    Mrgr.Label.Webhook.update(payload)
  end

  def handle("label", %{"action" => "deleted"} = payload) do
    Mrgr.Label.Webhook.delete(payload)
  end

  def handle("push", payload) do
    Mrgr.Branch.push(payload)
  end

  # ignore comments being deleted, who cares if we're off by a little bit
  def handle("pull_request_review_comment" = object, %{"action" => "created"} = payload) do
    Mrgr.PullRequest.add_pull_request_review_comment(object, payload)
  end

  def handle("issue_comment" = object, %{"action" => "created"} = payload) do
    Mrgr.PullRequest.add_issue_comment(object, payload)
  end

  def handle("pull_request_review", %{"action" => "submitted"} = payload) do
    Mrgr.PullRequest.Webhook.add_pr_review(payload)
  end

  def handle("pull_request_review", %{"action" => "dismissed"} = payload) do
    Mrgr.PullRequest.Webhook.dismiss_pr_review(payload)
  end

  ### handlers go above ^^^
  #
  #
  ### DEFAULT HANDLER ###
  def handle(obj, payload) do
    IO.inspect("*** NOT IMPLEMENTED #{obj}:#{payload["action"]}")
    {:ok, payload}
  end

  def create_incoming_webhook_record(obj, action, headers, data) do
    attrs = %{
      source: "github",
      object: obj,
      action: action,
      data: data,
      headers: headers
    }

    Mrgr.IncomingWebhook.create(attrs)
  end
end
