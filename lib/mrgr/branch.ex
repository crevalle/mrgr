defmodule Mrgr.Branch do
  use Mrgr.PubSub.Event

  def push(payload) do
    # ...
    Mrgr.PubSub.broadcast(payload, topic(payload), @branch_pushed)
  end

  def topic(payload) do
    installation = Mrgr.Installation.find_by_external_id(payload["installation"]["id"])
    Mrgr.PubSub.Topic.installation(installation)
  end

  # until we get a proper representation of these structures, just parse the webhook
  def head_committed_at(%{"head_commit" => %{"timestamp" => ts}}) do
    {:ok, dt, _huh} = DateTime.from_iso8601(ts)
    dt
  end

  # `head_commit` came back as nil once.  why?  merge commit?
  def head_committed_at(_) do
    nil
  end
end
