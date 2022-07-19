defmodule Mrgr.Branch do
  use Mrgr.PubSub.Topic

  def push(payload) do
    # ...
    Mrgr.PubSub.broadcast(payload, topic(payload), @branch_pushed)
  end

  def topic(payload) do
    "installation:#{payload["installation"]["id"]}"
  end
end
