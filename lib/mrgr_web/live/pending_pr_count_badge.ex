defmodule MrgrWeb.Live.PendingPRCountBadge do
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
          |> assign(:pending_pull_request_count, 0)
          |> ok()

        _installation ->
          subscribe(current_user)

          socket
          |> assign(
            :pending_pull_request_count,
            Enum.count(Mrgr.PullRequest.pending_pull_requests(current_user))
          )
          |> ok()
      end
    else
      ok(socket)
    end
  end

  def render(assigns) do
    ~H"""
      <span class="bg-gray-100 group-hover:bg-gray-200 ml-3 inline-block py-0.5 px-3 text-xs font-medium rounded-full"> <%= @pending_pull_request_count %> </span>
    """
  end

  def subscribe(user) do
    topic = Mrgr.PubSub.Topic.installation(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  def handle_info(%{event: event}, socket)
      when event in [@pull_request_created, @pull_request_reopened] do
    count = socket.assigns.pending_pull_request_count

    socket
    |> assign(:pending_pull_request_count, count + 1)
    |> noreply()
  end

  def handle_info(%{event: @pull_request_closed}, socket) do
    count = socket.assigns.pending_pull_request_count

    socket
    |> assign(:pending_pull_request_count, count - 1)
    |> noreply()
  end

  def handle_info(%{event: _who_cares}, socket) do
    noreply(socket)
  end
end
