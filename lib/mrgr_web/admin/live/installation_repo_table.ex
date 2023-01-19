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
        <.page_nav page={@page} />

        <table class="min-w-full">
          <thead class="bg-white">
            <tr>
              <.th uppercase={true}>ID</.th>
              <.th uppercase={true}>Node ID</.th>
              <.th uppercase={true}>Name</.th>
              <.th uppercase={true}>Private?</.th>
              <.th uppercase={true}>Language</.th>
              <.th uppercase={true}>Updated</.th>
              <.th uppercase={true}>Created</.th>
            </tr>
          </thead>

          <%= for repo <- @page.entries do %>
            <.tr striped={true}>
              <.td><%= repo.id %></.td>
              <.td><%= repo.node_id %></.td>
              <.td>
                <.l href={Routes.admin_pull_request_path(@socket, :index, repo.id)}>
                  <%= repo.name %>
                </.l>
              </.td>
              <.td><MrgrWeb.Components.Repository.lock bool={repo.private} /></.td>
              <.td><.language_icon language={repo.language} /></.td>
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
      page =
        id
        |> Mrgr.Repository.for_installation()
        |> Mrgr.Repo.paginate()

      socket
      |> put_title("[Admin] Installation #{id}")
      |> assign(:page, page)
      |> assign(:installation_id, id)
      |> ok
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page =
      socket.assigns.installation_id
      |> Mrgr.Repository.for_installation()
      |> Mrgr.Repo.paginate(params)

    socket
    |> assign(:page, page)
    |> noreply()
  end
end
