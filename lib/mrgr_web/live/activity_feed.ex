defmodule MrgrWeb.Live.ActivityFeed do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      items = load_items(current_user)

      subscribe(current_user)

      socket
      |> assign(:items, items)
      |> ok()
    else
      ok(socket)
    end
  end

  def subscribe(%{current_installation_id: nil}), do: nil

  def subscribe(user) do
    topic = Mrgr.PubSub.Topic.installation(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  # until i figure out how to represent activity stream events, we translate
  # %IncomingWebhook{} into either a %PullRequest{} (because we need `files_changed`) or
  # the raw payload of a branch push event.  super ugly : (
  def load_items(%{current_installation_id: nil}), do: []

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
    case find(item.data) do
      %Mrgr.Schema.PullRequest{} = pull_request ->
        %{event: "pull_request:#{item.action}", payload: pull_request}

      nil ->
        %{}
    end
  end

  def find(data) do
    Mrgr.PullRequest.find_for_activity_feed(data["pull_request"]["id"])
  end

  def render(assigns) do
    ~H"""
    <div class="shadow-inner">
      <div class="mx-2">
        <.h3>Latest Activity</.h3>
        <ul role="list" class="divide-y divide-gray-200">
          <MrgrWeb.Components.ActivityComponent.render :for={%{event: e, payload: p} <- @items} event={e} payload={p} tz={@timezone}) />
        </ul>
      </div>
    </div>
    """
  end

  def handle_info(%{event: "file_change_alert:" <> _event_type}, socket) do
    items = load_items(socket.assigns.current_user)

    socket
    |> assign(:items, items)
    |> noreply()
  end

  def handle_info(%{event: event, payload: _payload} = item, socket)
      when event in [
             @branch_pushed,
             @pull_request_created,
             @pull_request_reopened,
             @pull_request_synchronized,
             @pull_request_closed
           ] do
    items = socket.assigns.items

    socket
    |> assign(:items, [item | items])
    |> noreply()
  end

  def handle_info(%{event: _whatever}, socket) do
    socket
    |> noreply()
  end
end
