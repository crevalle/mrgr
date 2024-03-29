defmodule MrgrWeb.Admin.Live.IncomingWebhook do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Admin

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <.heading title="Webhooks we've Received" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="mt-1">
          <.page_nav page={@page} />

          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th>ID</.th>
                <.th>Installation</.th>
                <.th>PR Number</.th>
                <.th>object</.th>
                <.th>action</.th>
                <.th>received</.th>
                <.th></.th>
              </tr>
            </thead>

            <%= for hook <- @page.entries do %>
              <.tr striped={true}>
                <.td><%= hook.id %></.td>
                <.td>
                  <.link_to_installation installation={hook.installation} />
                </.td>
                <.td><%= pr_number(hook) %></.td>
                <.td>
                  <%= link(hook.object,
                    to: Routes.admin_incoming_webhook_path(@socket, :show, hook.id),
                    class: "text-teal-700 hover:text-teal-500"
                  ) %>
                </.td>
                <.td><%= hook.action %></.td>
                <.td><%= ts(hook.inserted_at, assigns.timezone) %></.td>
                <.td>
                  <.button
                    phx-click={JS.push("fire", value: %{id: hook.id})}
                    phx-disable-with="Firing 🚀..."
                    class="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500"
                  >
                    Fire!
                  </.button>
                </.td>
              </.tr>
            <% end %>
          </table>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe()

      page = Mrgr.IncomingWebhook.paged()

      socket
      |> assign(:page, page)
      |> put_title("Webhooks")
      |> ok()
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page = Mrgr.IncomingWebhook.paged(params)

    socket
    |> assign(:page, page)
    |> noreply()
  end

  def handle_event("fire", %{"id" => id}, socket) do
    hook = Mrgr.List.find(socket.assigns.page.entries, id)

    Mrgr.IncomingWebhook.fire!(hook)

    socket
    |> Flash.put(:info, "fired! 🚀")
    |> noreply()
  end

  def subscribe do
    Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())
  end

  def handle_info(%{event: @incoming_webhook_created, payload: payload}, socket) do
    hooks = socket.assigns.page.entries

    socket = assign(socket, :page, %{socket.assigns.page | entries: [payload | hooks]})
    {:noreply, socket}
  end

  # ignore other messages
  def handle_info(%{event: _}, socket), do: {:noreply, socket}

  def pr_number(%{data: %{"pull_request" => %{"number" => number}}}), do: number
  def pr_number(_), do: ""
end
