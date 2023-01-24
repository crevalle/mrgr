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

  def installation_table(assigns) do
    ~H"""
    <table class="min-w-full">
      <.table_attr obj={@installation} key={:state} . />
      <.table_attr obj={@installation} key={:app_id} . />
      <.table_attr obj={@installation} key={:app_slug} . />
      <.table_attr obj={@installation} key={:events} . />
      <.table_attr obj={@installation} key={:external_id} . />
      <.table_attr obj={@installation} key={:html_url} . />
      <.table_attr obj={@installation} key={:installation_created_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:permissions} . />
      <.table_attr obj={@installation} key={:repositories_url} . />
      <.table_attr obj={@installation} key={:repository_selection} . />
      <.table_attr obj={@installation} key={:target_id} . />
      <.table_attr obj={@installation} key={:target_type} . />
      <.table_attr obj={@installation} key={:access_tokens_url} . />
      <.table_attr obj={@installation} key={:token} tz={@tz} . />
      <.table_attr obj={@installation} key={:token_expires_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:updated_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:inserted_at} tz={@tz} . />
    </table>
    """
  end

  def admin_user_table(assigns) do
    ~H"""
    <table class="min-w-full">
      <thead class="bg-white">
        <tr>
          <.th uppercase={true}>ID</.th>
          <.th uppercase={true}>Current Installation</.th>
          <.th uppercase={true}>nickname</.th>
          <.th uppercase={true}>Full Name</.th>
          <.th uppercase={true}>last Seen</.th>
          <.th uppercase={true}>created</.th>
          <.th uppercase={true}>updated</.th>
        </tr>
      </thead>

      <%= for user <- @users do %>
        <.tr striped={true}>
          <.td>
            <%= link(user.id,
              to: Routes.admin_user_path(MrgrWeb.Endpoint, :show, user.id),
              class: "text-teal-700 hover:text-teal-500"
            ) %>
          </.td>
          <.td><%= link_to_installation(user) %></.td>
          <.td><%= user.nickname %></.td>
          <.td><%= user.name %></.td>
          <.td><%= ts(user.last_seen_at, @tz) %></.td>
          <.td><%= ts(user.inserted_at, @tz) %></.td>
          <.td><%= ts(user.updated_at, @tz) %></.td>
        </.tr>
      <% end %>
    </table>
    """
  end

  def link_to_installation(user) do
    title = current_account(user)
    installation_id = user.current_installation_id

    opts = [
      to: Routes.admin_installation_path(MrgrWeb.Endpoint, :show, installation_id),
      class: "text-teal-700 hover:text-teal-500"
    ]

    link(title, opts)
  end

  defp current_account(%{current_installation: %{account: %{login: login}}}), do: login
  defp current_account(user), do: user.current_installation_id
end
