defmodule MrgrWeb.Live.ActivityFeed do
  use MrgrWeb, :live_view

  def mount(params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      items = load_items(current_user)

      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:items, [])
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:items, [])
      |> ok()
    end
  end

  def subscribe(user) do
    topic = Mrgr.Installation.topic(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  def load_items(user) do
  end

  def render(assigns) do
    ~H"""
    <div>
      <h3>Latest Activity</h3>
      <ul role="list" class="divide-y divide-gray-200">
        <%= for %{event: e, payload: p} <- @items do %>
          <MrgrWeb.Components.ActivityComponent.render event={e} payload={p} tz={@timezone}) />
        <% end %>
      </ul>
    </div>
    """
  end

  def handle_info(%{event: event, payload: payload} = item, socket) do
    items = socket.assigns.items

    socket
    |> assign(:items, [item | items])
    |> noreply()
  end
end
