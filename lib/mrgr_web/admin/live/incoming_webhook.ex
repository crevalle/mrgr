defmodule MrgrWeb.Admin.Live.IncomingWebhook do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title="Webhooks we've Received" />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">

          <div class="mt-1">

            <table class="min-w-full">
              <thead class="bg-white">
                <tr>
                  <.th uppercase={true}>ID</.th>
                  <.th uppercase={true}>Installation</.th>
                  <.th uppercase={true}>object</.th>
                  <.th uppercase={true}>action</.th>
                  <.th uppercase={true}>received</.th>
                  <.th uppercase={true}></.th>
                </tr>
              </thead>

              <%= for hook <- @incoming_webhooks do %>
                <.tr striped={true}>
                  <.td><%= link hook.id, to: Routes.admin_incoming_webhook_path(@socket, :show, hook.id), class: "text-teal-500" %></.td>
                  <.td><%= hook.installation_id %></.td>
                  <.td><%= hook.object %></.td>
                  <.td><%= hook.action %></.td>
                  <.td><%= ts(hook.inserted_at, assigns.timezone) %></.td>
                  <.td>
                    <.button phx-click="fire" phx-value-id={hook.id} phx_disable_with="Firing 🚀..." colors="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500">Fire!</.button>
                  </.td>
                </.tr>
              <% end %>
            </table>


          </div>

        </div>
      </div>
    </div>

    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe()

      hooks = Mrgr.IncomingWebhook.all()
      {:ok, assign(socket, :incoming_webhooks, hooks)}
    else
      {:ok, assign(socket, :incoming_webhooks, [])}
    end
  end

  def handle_event("fire", %{"id" => id}, socket) do
    hook = Mrgr.List.find(socket.assigns.incoming_webhooks, id)

    Mrgr.IncomingWebhook.fire!(hook)

    socket
    |> put_flash(:info, "fired! 🚀")
    |> noreply()
  end

  def subscribe do
    Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())
  end

  def handle_info(%{event: @incoming_webhook_created, payload: payload}, socket) do
    hooks = socket.assigns.incoming_webhooks
    socket = assign(socket, :incoming_webhooks, [payload | hooks])
    {:noreply, socket}
  end

  # ignore other messages
  def handle_info(%{event: _}, socket), do: {:noreply, socket}
end
