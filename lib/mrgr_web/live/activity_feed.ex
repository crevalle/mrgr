defmodule MrgrWeb.Live.ActivityFeed do
  use MrgrWeb, :live_view

  def mount(params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      events = load_events(current_user)

      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:events, [])
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:events, [])
      |> ok()
    end
  end

  def subscribe(user) do
    topic = Mrgr.Installation.topic(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  def load_events(user) do
  end

  def render(assigns) do
    ~H"""


    <ul>
      <%= for e <- @events do %>
        <MrgrWeb.Components.ActivityComponent.render event={e}) />
      <% end %>
    </ul>
    """
  end

  def handle_info(%{event: "branch:pushed", payload: payload}, socket) do
    events = socket.assigns.events

    socket
    |> assign(:events, [payload | events])
    |> noreply()
  end
end
