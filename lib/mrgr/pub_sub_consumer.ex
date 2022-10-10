defmodule Mrgr.PubSubConsumer do
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    installation = Mrgr.Installation.i()

    topic = Mrgr.PubSub.Topic.installation(installation)

    Mrgr.PubSub.subscribe(topic)
    Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())

    {:ok, %{}}
  end

  def handle_info(%{event: event}, state) do
    IO.inspect(event, label: "[PubSub Consumer] got event")

    {:noreply, state}
  end
end
