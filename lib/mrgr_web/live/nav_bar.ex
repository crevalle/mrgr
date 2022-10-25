defmodule MrgrWeb.Live.NavBar do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      case current_user.current_installation do
        nil ->
          # onboarding, no current installation
          socket
          |> assign(:pending_merge_count, 0)
          |> ok()

        _installation ->
          subscribe(current_user)

          socket
          |> assign(:pending_merge_count, Enum.count(Mrgr.Merge.pending_merges(current_user)))
          |> ok()
      end
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
