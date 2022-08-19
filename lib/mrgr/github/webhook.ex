defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  def handle_webhook(headers, params) do
    obj = headers["x-github-event"]
    action = params["action"]

    _hook = create_incoming_webhook_record(obj, action, headers, params)

    Mrgr.Github.Webhook.handle(obj, params)
  end

  def handle("installation", %{"action" => "created"} = payload) do
    Mrgr.Installation.create_from_webhook(payload)
  end

  def handle("installation", %{"action" => "deleted"} = payload) do
    Mrgr.Installation.delete_from_webhook(payload)
  end

  # def handle("installation", %{"action" => "requested"} = payload) do
  # payload
  # end

  def handle("pull_request", %{"action" => "opened"} = payload) do
    Mrgr.Merge.create_from_webhook(payload)
  end

  def handle("pull_request", %{"action" => "reopened"} = payload) do
    Mrgr.Merge.reopen(payload)
  end

  def handle("pull_request", %{"action" => "closed"} = payload) do
    Mrgr.Merge.close(payload)
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def handle("pull_request", %{"action" => "synchronize"} = payload) do
    Mrgr.Merge.synchronize(payload)
    # Mrgr.CheckRun.create(payload)
  end

  def handle("push", payload) do
    Mrgr.Branch.push(payload)
  end

  # def handle("check_suite", %{"action" => "requested"} = payload) do
  # # Mrgr.CheckRun.create(payload)
  # payload
  # end

  # suspended?
  def handle(obj, payload) do
    IO.inspect("*** NOT IMPLEMENTED #{obj}")
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
