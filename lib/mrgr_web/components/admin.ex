defmodule MrgrWeb.Components.Admin do
  use MrgrWeb, :component

  # import MrgrWeb.JS
  import MrgrWeb.Components.UI

  def subscription(%{subscription: nil} = assigns) do
    ~H"""
    <.section>
      <:title>
        Subscription
      </:title>

      <p class="italic">No subscription!</p>
    </.section>
    """
  end

  def subscription(assigns) do
    ~H"""
    <.section>
      <:title>
        Subscription
      </:title>

      <table class="w-full">
        <thead class="bg-white">
          <tr>
            <.th uppercase={true}>ID</.th>
            <.th uppercase={true}>Node ID</.th>
            <.th uppercase={true}>Webhook</.th>
            <.th uppercase={true}>created</.th>
          </tr>
        </thead>
        <.tr striped={true}>
          <.td><%= @subscription.id %></.td>
          <.td><%= @subscription.node_id %></.td>
          <.td>
            <.l href={
              Routes.admin_stripe_webhook_path(MrgrWeb.Endpoint, :show, @subscription.webhook_id)
            }>
              <%= @subscription.webhook_id %>
            </.l>
          </.td>
          <.td><%= ts(@subscription.inserted_at, @tz) %></.td>
        </.tr>
      </table>
    </.section>
    """
  end

  def section(assigns) do
    ~H"""
    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="my-1">
          <.h3><%= render_slot(@title) %></.h3>
        </div>

        <div class="mt-1">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
