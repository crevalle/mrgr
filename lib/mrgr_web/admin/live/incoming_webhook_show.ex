defmodule MrgrWeb.Admin.Live.IncomingWebhookShow do
  use MrgrWeb, :live_view

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"Incoming Webhook #{@hook.id}"} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="mt-1">
            <table class="min-w-full">
              <thead class="bg-white">
                <tr>
                  <.th>Object</.th>
                  <.th>Action</.th>
                  <.th>Account</.th>
                  <.th>Received</.th>
                </tr>
              </thead>

              <.tr>
                <.td><%= @hook.object %></.td>
                <.td><%= @hook.action %></.td>
                <.td><%= account(@hook) %></.td>
                <.td><%= ts(@hook.inserted_at, assigns.timezone) %></.td>
              </.tr>
            </table>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="flex items-center justify-between my-1">
            <.h3>Headers</.h3>
            <.copy_button target="#headers-json" />
          </div>

          <pre id="headers-json">
            <%= render_map(@hook.headers) %>
          </pre>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="flex items-center justify-between my-1">
            <.h3>Raw Data</.h3>
            <.copy_button target="#data-json" />
          </div>

          <pre id="data-json">
            <%= render_map(@hook.data) %>
          </pre>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    hook = Mrgr.IncomingWebhook.get(id)

    socket
    |> assign(hook: hook)
    |> put_title("Webhook #{hook.id}")
    |> ok
  end

  defp account(%{installation: %{account: %{login: login}}}), do: login
  defp account(_), do: "-"
end
