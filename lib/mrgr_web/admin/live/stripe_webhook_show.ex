defmodule MrgrWeb.Admin.Live.StripeWebhookShow do
  use MrgrWeb, :live_view

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"Stripe Webhook #{@hook.id}"} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="mt-1">
            <table class="min-w-full">
              <thead class="bg-white">
                <tr>
                  <.th uppercase={true}>External ID</.th>
                  <.th uppercase={true}>Type</.th>
                  <.th uppercase={true}>Received</.th>
                </tr>
              </thead>

              <.tr>
                <.td><%= @hook.external_id %></.td>
                <.td><%= @hook.type %></.td>
                <.td><%= ts(@hook.inserted_at, assigns.timezone) %></.td>
              </.tr>
            </table>
          </div>
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
    hook = Mrgr.Stripe.Webhook.get(id)

    socket
    |> assign(hook: hook)
    |> put_title("Webhook #{hook.id}")
    |> ok
  end
end
