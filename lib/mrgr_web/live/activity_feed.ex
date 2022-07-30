defmodule MrgrWeb.Live.ActivityFeed do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      items = load_items(current_user)

      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:items, items)
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:items, [])
      |> ok()
    end
  end

  def subscribe(user) do
    topic = Mrgr.PubSub.Topic.installation(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  # until i figure out how to represent activity stream events, we translate
  # %IncomingWebhook{} into either a %Merge{} (because we need `files_changed`) or
  # the raw payload of a branch push event.  super ugly : (
  def load_items(user) do
    user
    |> Mrgr.ActivityFeed.load_for_user()
    |> Enum.filter(fn %{object: obj} ->
      obj == "pull_request" || obj == "push"
    end)
    |> Enum.map(fn item ->
      create_event(item)
    end)
  end

  defp create_event(%{object: "push"} = item) do
    %{event: @branch_pushed, payload: item.data}
  end

  defp create_event(item) do
    merge = Mrgr.Merge.find_for_activity_feed(item.data["pull_request"]["id"])
    %{event: "merge:#{item.action}", payload: merge}
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

  def handle_info(%{event: "file_change_alert:" <> _event_type}, socket) do
    items = load_items(socket.assigns.current_user)

    socket
    |> assign(:items, items)
    |> noreply()
  end

  def handle_info(%{event: _event, payload: _payload} = item, socket) do
    items = socket.assigns.items

    socket
    |> assign(:items, [item | items])
    |> noreply()
  end
end
