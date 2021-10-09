defmodule Mrgr.Github.Webhook do
  @moduledoc """
    Dispatcher that receives webhooks and figures out what to do with them.
  """

  def process(%{"installation" => _params, "action" => "created"} = payload) do
    Mrgr.Installation.create_from_webhook(payload)
  end

  def process(%{"installation" => _params, "action" => "deleted"} = payload) do
    Mrgr.Installation.delete_from_webhook(payload)
  end

  def process(%{"installation" => _params, "action" => "requested"} = payload) do
    payload
  end

  def process(%{"pull_request" => _params, "action" => "opened" } = payload) do
    payload
  end

  def process(%{"pull_request" => _params, "action" => "closed", "merged" => true} = payload) do
    # merged
    payload
  end

  def process(%{"pull_request" => _params, "action" => "closed", "merged" => false} = payload) do
    # closed, not merged
    payload
  end

  # HEAD OF PR IS UPDATED - create a new check suite/run, new checklist
  def process(%{"action" => "synchronize", "pull_request" => _params} = payload) do
    IO.inspect("GOT SYNCHRONIZE")
    payload
  end

  def process(%{"action" => "requested", "check_suite" => _params} = payload) do
    Mrgr.CheckRun.process(payload)
  end

  # suspended?
  def process(payload), do: payload

end
