defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  def handle("installation", %{"action" => "created"} = payload) do
    Mrgr.Installation.create_from_webhook(payload)
  end

  def handle("installation", %{"action" => "deleted"} = payload) do
    Mrgr.Installation.delete_from_webhook(payload)
  end

  def handle("installation", %{"action" => "requested"} = payload) do
    payload
  end

  def handle("pull_request", %{"action" => "opened"} = payload) do
    Mrgr.Merge.create_from_webhook(payload)
    payload
  end

  def handle("pull_request", %{"action" => "reopened"} = payload) do
    # Mrgr.Merge.reopen(payload)
    payload
  end

  def handle("pull_request", %{"action" => "closed", "merged" => true} = payload) do
    # merged
    payload
  end

  def handle("pull_request", %{"action" => "closed", "merged" => false} = payload) do
    # closed, not merged
    payload
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def handle("pull_request", %{"action" => "synchronize"} = payload) do
    Mrgr.CheckRun.create(payload)
    payload
  end

  def handle("check_suite", %{"action" => "requested"} = payload) do
    # Mrgr.CheckRun.create(payload)
    payload
  end

  # suspended?
  def handle(_obj, payload), do: payload
end
