defmodule MrgrWeb.Admin.Live.NotificationListTable do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def render(assigns) do
    ~H"""
    <div class="px-4 py-5 sm:px-6">
      <div class="my-1">
        <.h3>Notifications (<%= @page.total_entries %> total)</.h3>
      </div>

      <div class="mt-1">
        <.page_nav page={@page} />

        <table class="min-w-full">
          <thead class="bg-white">
            <tr>
              <.th>ID</.th>
              <.th>Channel</.th>
              <.th>Type</.th>
              <.th>Sent</.th>
              <.th>Error</.th>
            </tr>
          </thead>

          <%= for notification <- @page.entries do %>
            <.tr striped={true}>
              <.td><%= notification.id %></.td>
              <.td><.channel_icon channel={notification.channel} /></.td>
              <.td><%= notification.type %></.td>
              <.td><%= ts(notification.inserted_at, @timezone) %></.td>
              <.td><%= notification.error %></.td>
            </.tr>
          <% end %>
        </table>
      </div>
    </div>
    """
  end

  def mount(_params, %{"id" => id}, socket) do
    if connected?(socket) do
      page = Mrgr.Notification.paged_for_user(id)

      socket
      |> put_title("[Admin] Notifications")
      |> assign(:page, page)
      |> assign(:user_id, id)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page = Mrgr.Notification.paged_for_user(socket.assigns.user_id, params)

    socket
    |> assign(:page, page)
    |> noreply()
  end
end
