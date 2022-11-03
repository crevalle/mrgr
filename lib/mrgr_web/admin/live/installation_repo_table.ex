defmodule MrgrWeb.Admin.Live.InstallationRepoTable do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth
  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
      <div class="px-4 py-5 sm:px-6">
        <div class="my-1">
          <.h3>Repositories (<%= @page.total_entries %> total)</.h3>
        </div>

        <div class="mt-1">
          <nav class="border-t border-gray-200">
            <ul class="flex my-2">
              <li class="">
                <a class={"px-2 py-2 #{if @page.page_number <= 1, do: "pointer-events-none text-gray-600", else: "text-teal-400"}"} href="#" phx-click="nav" phx-value-page={@page.page_number + 1}>Previous</a>
              </li>
              <%= for idx <-  Enum.to_list(1..@page.total_pages) do %>
                <li class="">
                  <a class={"px-2 py-2 #{if @page.page_number == idx, do: "pointer-events-none text-gray-600", else: "text-teal-400"}"} href="#" phx-click="nav" phx-value-page={idx}><%= idx %></a>
                </li>
              <% end %>
              <li class="">
                <a class={"px-2 py-2 #{if @page.page_number >= @page.total_pages, do: "pointer-events-none text-gray-600", else: "text-teal-400"}"} href="#" phx-click="nav" phx-value-page={@page.page_number + 1}>Next</a>
              </li>
            </ul>
          </nav>

          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th uppercase={true}>ID</.th>
                <.th uppercase={true}>Node ID</.th>
                <.th uppercase={true}>Name</.th>
                <.th uppercase={true}>Private?</.th>
                <.th uppercase={true}>Merge Freeze Enabled?</.th>
                <.th uppercase={true}>Updated</.th>
                <.th uppercase={true}>Created</.th>
              </tr>
            </thead>

            <%= for repo <- @page.entries do %>
              <.tr striped={true}>
                <.td><%= repo.id %></.td>
                <.td><%= repo.node_id %></.td>
                <.td><%= repo.name %></.td>
                <.td><MrgrWeb.Components.Repository.lock bool={repo.private} /></.td>
                <.td><%= repo.merge_freeze_enabled %></.td>
                <.td><%= ts(repo.updated_at, @timezone) %></.td>
                <.td><%= ts(repo.inserted_at, @timezone) %></.td>
              </.tr>
            <% end %>
          </table>
        </div>
      </div>

    """
  end

  def mount(_params, %{"id" => id}, socket) do
    if connected?(socket) do
      page = Mrgr.Repository.for_installation(id)

      socket
      |> put_title("[Admin] Installation #{id}")
      |> assign(:page, page)
      |> assign(:installation_id, id)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("nav", params, socket) do
    page = Mrgr.Repository.for_installation(socket.assigns.installation_id, params)

    IO.inspect(params)

    socket
    |> assign(:page, page)
    |> noreply()
  end
end
