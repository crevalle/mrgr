defmodule MrgrWeb.Live.NavBar do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      pending_merge_count = Enum.count(Mrgr.Merge.pending_merges(current_user))

      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:pending_merge_count, pending_merge_count)
      |> ok()
    else
      ok(socket)
    end
  end

  def subscribe(user) do
    topic = Mrgr.PubSub.Topic.installation(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  def handle_info(%{event: event}, socket) when event in [@merge_created, @merge_reopened] do
    count = socket.assigns.pending_merge_count

    socket
    |> assign(:pending_merge_count, count + 1)
    |> noreply()
  end

  def handle_info(%{event: @merge_closed}, socket) do
    count = socket.assigns.pending_merge_count

    socket
    |> assign(:pending_merge_count, count - 1)
    |> noreply()
  end

  def handle_info(%{event: _who_cares}, socket) do
    noreply(socket)
  end
end
