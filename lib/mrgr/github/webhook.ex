defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  def handle(%{"installation" => _params, "action" => "created"} = payload) do
    Mrgr.Installation.create_from_webhook(payload)
  end

  def handle(%{"installation" => _params, "action" => "deleted"} = payload) do
    Mrgr.Installation.delete_from_webhook(payload)
  end

  def handle(%{"installation" => _params, "action" => "requested"} = payload) do
    payload
  end

  def handle(%{"pull_request" => _params, "action" => "opened" } = payload) do
    payload
  end

  def handle(%{"pull_request" => _params, "action" => "closed", "merged" => true} = payload) do
    # merged
    payload
  end

  def handle(%{"pull_request" => _params, "action" => "closed", "merged" => false} = payload) do
    # closed, not merged
    payload
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def handle(%{"action" => "synchronize", "pull_request" => _params} = payload) do
    IO.inspect("GOT SYNCHRONIZE")
    payload
  end

  def handle(%{"action" => "requested", "check_suite" => _params} = payload) do
    Mrgr.CheckRun.process(payload)
  end

  # suspended?
  def handle(payload), do: payload

end
