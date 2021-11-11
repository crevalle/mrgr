defmodule Mrgr.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(payload, topic, event) do
    data = %{payload: payload, topic: topic, event: event}
    Phoenix.PubSub.broadcast(__MODULE__, topic, data)
  end
end
