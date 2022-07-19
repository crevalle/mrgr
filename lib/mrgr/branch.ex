defmodule Mrgr.Branch do
  def push(payload) do
    # ...
    Mrgr.PubSub.broadcast(payload, topic(payload), "branch:pushed")
  end

  def topic(payload) do
    "installation:#{payload["installation"]["id"]}"
  end
end
