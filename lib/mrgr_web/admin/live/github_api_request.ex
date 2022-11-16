defmodule MrgrWeb.Admin.Live.GithubAPIRequest do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event
  on_mount MrgrWeb.Plug.Auth
  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <.heading title="Github API Requests" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">

        <div class="mt-1">
          <.page_nav page={@page} />

          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th uppercase={true}>ID</.th>
                <.th uppercase={true}>Installation</.th>
                <.th uppercase={true}>API Call</.th>
                <.th uppercase={true}>Response Code</.th>
                <.th uppercase={true}>Elapsed Time (ms)</.th>
                <.th uppercase={true}>Data</.th>
                <.th uppercase={true}>Response Headers</.th>
                <.th uppercase={true}>Updated</.th>
                <.th uppercase={true}>Created</.th>
              </tr>
            </thead>

            <%= for r <- @page.entries do %>
              <.tr striped={true}>
                <.td><%= r.id %></.td>
                <.td><%= link r.installation.account.login, to: Routes.admin_installation_path(MrgrWeb.Endpoint, :show, r.installation_id), class: "text-teal-700 hover:text-teal-500" %></.td>
                <.td><%= shorten(r.api_call) %></.td>
                <.td><%= r.response_code %></.td>
                <.td><%= r.elapsed_time %></.td>
                <.td>
                  <.live_component module={MrgrWeb.Components.Live.JSONModalComponent} id={"data-modal-#{r.id}"} title={"Request #{r.id} Data"} data={r.data} ./>
                </.td>
                <.td>
                  <.live_component module={MrgrWeb.Components.Live.JSONModalComponent} id={"headers-modal-#{r.id}"} title={"Request #{r.id} Response Headers"} data={r.response_headers} ./>
                </.td>
                <.td><%= ts(r.updated_at, @timezone) %></.td>
                <.td><%= ts(r.inserted_at, @timezone) %></.td>
              </.tr>
            <% end %>
          </table>

        </div>

      </div>
    </div>
    """
  end

  def handle_event("show-modal", %{"id" => component_id}, socket) do
    send_update(MrgrWeb.Components.Live.JSONModalComponent, id: "#{component_id}", state: "open")

    {:noreply, socket}
  end

  def handle_event("hide-modal", %{"id" => component_id}, socket) do
    send_update(MrgrWeb.Components.Live.JSONModalComponent, id: "#{component_id}", state: "closed")

    {:noreply, socket}
  end

  def handle_event("nav", params, socket) do
    page = Mrgr.Github.API.paged_requests(params)

    socket
    |> assign(:page, page)
    |> noreply()
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe()

      page = Mrgr.Github.API.paged_requests()

      socket
      |> assign(:page, page)
      |> put_title("API Requests")
      |> ok()
    else
      {:ok, socket}
    end
  end

  def subscribe do
    Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())
  end

  def handle_info(%{event: @api_request_completed, payload: api_request}, socket) do
    requests = [api_request] ++ socket.assigns.requests

    socket
    |> assign(:requests, requests)
    |> noreply()
  end

  # ignore other messages
  def handle_info(%{event: _}, socket), do: {:noreply, socket}
end
