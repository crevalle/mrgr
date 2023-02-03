defmodule MrgrWeb.Admin.Live.StripeWebhook do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <.heading title="Stripe Webhooks" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="mt-1">
          <.page_nav page={@page} />

          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th uppercase={true}>ID</.th>
                <.th uppercase={true}>External ID</.th>
                <.th uppercase={true}>Type</.th>
                <.th uppercase={true}>Created</.th>
                <.th uppercase={true}>Received</.th>
              </tr>
            </thead>

            <%= for hook <- @page.entries do %>
              <.tr striped={true}>
                <.td><%= hook.id %></.td>
                <.td><%= hook.external_id %></.td>
                <.td>
                  <.l href={Routes.admin_stripe_webhook_path(@socket, :show, hook.id)}>
                    <%= hook.type %>
                  </.l>
                </.td>
                <.td><%= ts(parse_created(hook), assigns.timezone) %></.td>
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
      page = Mrgr.Repo.paginate(Mrgr.Stripe.Webhook.list())

      socket
      |> assign(:page, page)
      |> put_title("Admin - Stripe Webhooks")
      |> ok()
    else
      {:ok, socket}
    end
  end

  def handle_event("paginate", params, socket) do
    page = Mrgr.Repo.paginate(Mrgr.Stripe.Webhook.list(), params)

    socket
    |> assign(:page, page)
    |> noreply()
  end

  def handle_event("fire", %{"id" => id}, socket) do
    hook = Mrgr.List.find(socket.assigns.page.entries, id)

    Mrgr.Stripe.Webhook.fire!(hook)

    socket
    |> Flash.put(:info, "fired! 🚀")
    |> noreply()
  end

  def parse_created(hook) do
    {:ok, datetime} = DateTime.from_unix(hook.created)
    datetime
  end
end
