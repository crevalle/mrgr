defmodule Mrgr.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(__MODULE__, topic)
  end

  def broadcast(payload, topic, event) do
    data = %{payload: payload, topic: topic, event: event}
    Phoenix.PubSub.broadcast(__MODULE__, topic, data)
  end

  defmodule Topic do
    defmacro __using__(_opts) do
      quote do
        @branch_pushed "branch:pushed"

        @merge_created "merge:created"
        @merge_reopened "merge:reopened"
        @merge_synchronized "merge:synchronized"
        @merge_closed "merge:closed"
      end
    end
  end
end
