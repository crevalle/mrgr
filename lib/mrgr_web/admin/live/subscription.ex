defmodule MrgrWeb.Admin.Live.Subscription do
  use MrgrWeb, :live_view
  import MrgrWeb.Components.Admin

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <.heading title="Subscriptions" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="mt-1">
          <.section>
            <:title>
              Subscriptions
            </:title>

            <table class="w-full">
              <thead class="bg-white">
                <tr>
                  <.th>ID</.th>
                  <.th>Node ID</.th>
                  <.th>Installation</.th>
                  <.th>Webhook</.th>
                  <.th>created</.th>
                </tr>
              </thead>
              <.tr :for={subscription <- @subscriptions} striped={true}>
                <.td><%= subscription.id %></.td>
                <.td><%= subscription.node_id %></.td>
                <.td>
                  <.l href={
                    Routes.admin_installation_path(
                      MrgrWeb.Endpoint,
                      :show,
                      subscription.installation.id
                    )
                  }>
                    <%= subscription.installation.account.login %>
                  </.l>
                </.td>
                <.td>
                  <.l href={
                    Routes.admin_stripe_webhook_path(MrgrWeb.Endpoint, :show, subscription.webhook_id)
                  }>
                    <%= subscription.webhook_id %>
                  </.l>
                </.td>
                <.td><%= ts(subscription.inserted_at, @timezone) %></.td>
              </.tr>
            </table>
          </.section>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscriptions = Mrgr.Repo.all(Mrgr.Stripe.Subscription.all())
      {:ok, assign(socket, :subscriptions, subscriptions)}
    else
      {:ok, socket}
    end
  end
end
