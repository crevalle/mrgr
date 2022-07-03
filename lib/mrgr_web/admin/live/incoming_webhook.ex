defmodule MrgrWeb.Admin.Live.IncomingWebhook do
  use MrgrWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Webhooks We've Received</h1>

    <table>
      <th>id</th>
      <th>Object</th>
      <th>Action</th>
      <th>Data</th>
      <th>Received</th>
      <th></th>

      <%= for hook <- @incoming_webhooks do %>
        <tr>
          <td><%= link hook.id, to: Routes.admin_incoming_webhook_path(@socket, :show, hook.id) %></td>
          <td><%= hook.object %></td>
          <td><%= hook.action %></td>
          <td></td>
          <td><%= ts(hook.inserted_at, assigns.timezone) %></td>
          <td><button phx-click="fire" phx-value-id={hook.id}>Fire!</button></td>
        </tr>
      <% end %>
    </table>
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
    id = String.to_integer(id)

    hook = Enum.find(socket.assigns.incoming_webhooks, &(&1.id == id))

    Mrgr.IncomingWebhook.fire!(hook)

    socket
    |> put_flash(:info, "fired! 🚀")
    |> noreply()
  end

  def subscribe do
    Mrgr.PubSub.subscribe(Mrgr.IncomingWebhook.topic())
  end

  def handle_info(%{event: "created", payload: payload}, socket) do
    hooks = socket.assigns.incoming_webhooks
    socket = assign(socket, :incoming_webhooks, [payload | hooks])
    {:noreply, socket}
  end
end
