defmodule MrgrWeb.Admin.Live.IncomingWebhookShow do
  use MrgrWeb, :live_view

  def render(assigns) do
    ~H"""
    <h1>Incoming Webhook<%= @hook.id %></h1>
    <table>
      <th>Object</th>
      <th>Action</th>
      <th>Account</th>
      <th>Received</th>

      <tr>
        <td><%= @hook.object %></td>
        <td><%= @hook.action %></td>
        <td><%= account(@hook) %></td>
        <td><%= ts(@hook.inserted_at, assigns.timezone) %></td>
      </tr>
    </table>

    <h3>Headers</h3>
    <pre>
      <%= Jason.encode!(@hook.headers, pretty: true) %>
    </pre>

    <h3>Raw Data</h3>
      <pre>
      <%= Jason.encode!(@hook.data, pretty: true) %>
    </pre>

    """
  end

  def mount(%{"id" => id}, session, socket) do
    hook = Mrgr.IncomingWebhook.get(id)

    socket
    |> assign(hook: hook)
    |> ok
  end

  defp account(%{installation: %{account: %{login: login}}}), do: login
  defp account(_), do: "-"
end
