defmodule MrgrWeb.Live.OpenPRCountBadge do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"installation_id" => id}, socket) do
    if connected?(socket) do
      case id do
        nil ->
          # onboarding, no current installation
          socket
          |> assign(:id, id)
          |> assign(:count, 0)
          |> ok()

        _installation ->
          subscribe(id)

          socket
          |> assign(:id, id)
          |> assign(:count, Mrgr.PullRequest.open_pr_count(id))
          |> ok()
      end
    else
      ok(socket)
    end
  end

  def render(assigns) do
    ~H"""
      <span class="bg-gray-100 group-hover:bg-gray-200 ml-3 inline-block py-0.5 px-3 text-xs font-medium rounded-full"> <%= @count %> </span>
    """
  end

  def subscribe(installation_id) do
    Mrgr.PubSub.subscribe_to_installation(installation_id)
  end

  def handle_info(%{event: event}, socket)
      when event in [@pull_request_created, @pull_request_reopened] do
    count = socket.assigns.count

    socket
    |> assign(:count, count + 1)
    |> noreply()
  end

  def handle_info(%{event: @pull_request_closed}, socket) do
    count = socket.assigns.count

    socket
    |> assign(:count, count - 1)
    |> noreply()
  end

  def handle_info(%{event: _who_cares}, socket) do
    noreply(socket)
  end
end