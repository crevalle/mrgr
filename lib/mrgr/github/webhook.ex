defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  @type t :: map()

  def handle_webhook(headers, params) do
    obj = headers["x-github-event"]
    action = params["action"]

    _hook = create_incoming_webhook_record(obj, action, headers, params)

    IO.inspect("*** HANDLING WEBHOOK: #{obj}:#{action}")

    Mrgr.Github.Webhook.handle(obj, params)
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
    Mrgr.Merge.create_from_webhook(payload)
  end

  def handle("pull_request", %{"action" => "reopened"} = payload) do
    Mrgr.Merge.reopen(payload)
  end

  def handle("pull_request", %{"action" => "edited"} = payload) do
    Mrgr.Merge.edit(payload)
  end

  def handle("pull_request", %{"action" => "closed"} = payload) do
    Mrgr.Merge.close(payload)
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def handle("pull_request", %{"action" => "synchronize"} = payload) do
    Mrgr.Merge.synchronize(payload)
    # Mrgr.CheckRun.create(payload)
  end

  def handle("pull_request", %{"action" => "assigned"} = payload) do
    Mrgr.Merge.Webhook.assign_user(payload)
  end

  def handle("pull_request", %{"action" => "unassigned"} = payload) do
    Mrgr.Merge.Webhook.unassign_user(payload)
  end

  def handle("pull_request", %{"action" => "review_requested"} = payload) do
    Mrgr.Merge.Webhook.add_reviewer(payload)
  end

  def handle("pull_request", %{"action" => "review_request_removed"} = payload) do
    Mrgr.Merge.Webhook.remove_reviewer(payload)
  end

  def handle("push", payload) do
    Mrgr.Branch.push(payload)
  end

  # ignore comments being deleted, who cares if we're off by a little bit
  def handle("pull_request_review_comment" = object, %{"action" => "created"} = payload) do
    Mrgr.Merge.add_pull_request_review_comment(object, payload)
  end

  def handle("issue_comment" = object, %{"action" => "created"} = payload) do
    Mrgr.Merge.add_issue_comment(object, payload)
  end

  def handle("pull_request_review", %{"action" => "submitted"} = payload) do
    Mrgr.Merge.Webhook.add_pr_review(payload)
  end

  ### handlers go above ^^^
  #
  #
  ### DEFAULT HANDLER ###
  def handle(obj, payload) do
    IO.inspect("*** NOT IMPLEMENTED #{obj} ACTION #{payload["action"]}")
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
