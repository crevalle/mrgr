defmodule MrgrWeb.Admin.Live.InstallationMemberTable do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 py-5 sm:px-6">
      <div class="my-1">
        <.h3>Members (<%= @page.total_entries %> total)</.h3>
      </div>

      <div class="mt-1">
        <.page_nav page={@page} />

        <table class="min-w-full">
          <thead class="bg-white">
            <tr>
              <.th uppercase={true}>ID</.th>
              <.th uppercase={true}>Node ID</.th>
              <.th uppercase={true}>Login</.th>
              <.th uppercase={true}>Type</.th>
              <.th uppercase={true}>Updated</.th>
              <.th uppercase={true}>Created</.th>
            </tr>
          </thead>

          <%= for member <- @page.entries do %>
            <.tr striped={true}>
              <.td><%= member.id %></.td>
              <.td><%= member.node_id %></.td>
              <.td>
                <div class="flex">
                  <%= img_tag(member.avatar_url, class: "h-5 w-5 mr-2") %>
                  <%= member.login %>
                </div>
              </.td>
              <.td><%= member.type %></.td>
              <.td><%= ts(member.updated_at, @timezone) %></.td>
              <.td><%= ts(member.inserted_at, @timezone) %></.td>
            </.tr>
          <% end %>
        </table>
      </div>
    </div>
    """
  end

  def mount(_params, %{"id" => id}, socket) do
    if connected?(socket) do
      page = Mrgr.Member.paged_for_installation(id)

      socket
      |> put_title("[Admin] Members")
      |> assign(:page, page)
      |> assign(:installation_id, id)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page = Mrgr.Member.paged_for_installation(socket.assigns.installation_id, params)

    socket
    |> assign(:page, page)
    |> noreply()
  end
end
