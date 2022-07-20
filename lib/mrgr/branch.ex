defmodule Mrgr.Branch do
  use Mrgr.PubSub.Topic

  def push(payload) do
    # ...
    Mrgr.PubSub.broadcast(payload, topic(payload), @branch_pushed)
  end

  def topic(payload) do
    "installation:#{payload["installation"]["id"]}"
  end

  # until we get a proper representation of these structures, just parse the webhook
  def head_committed_at(%{"head_commit" => %{"timestamp" => ts}}) do
    {:ok, dt, _huh} = DateTime.from_iso8601(ts)
    dt
  end
end
