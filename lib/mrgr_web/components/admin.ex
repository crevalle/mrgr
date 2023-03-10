defmodule MrgrWeb.Components.Admin do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  alias Phoenix.LiveView.JS

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
            <.th>ID</.th>
            <.th>Node ID</.th>
            <.th>Webhook</.th>
            <.th>created</.th>
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
      <.tr striped={true}>
        <.td class="font-bold">Onboarding State</.td>
        <.td>
          <%= @installation.state %>
          <.l
            :if={!Mrgr.Installation.onboarded?(@installation)}
            phx-click={JS.push("re-onboard", value: %{id: @installation.id})}
            data={[confirm: "Sure about that?"]}
          >
            Re-onboard
          </.l>
        </.td>
      </.tr>
      <.tr striped={true}>
        <.td class="font-bold">State Changes</.td>
        <.td>
          <table>
            <.tr :for={sc <- Enum.reverse(@installation.state_changes)}>
              <td><%= sc.state %></td>
              <td><%= sc.transitioned_at %></td>
            </.tr>
          </table>
        </.td>
      </.tr>
      <.table_attr obj={@installation} key={:onboarding_error} . />
      <.table_attr obj={@installation} key={:subscription_state} . />
      <.tr striped={true}>
        <.td class="font-bold">Subscription State Changes</.td>
        <.td>
          <table>
            <.tr :for={sc <- Enum.reverse(@installation.subscription_state_changes)}>
              <td><%= sc.state %></td>
              <td><%= sc.transitioned_at %></td>
            </.tr>
          </table>
        </.td>
      </.tr>
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
          <.th>ID</.th>
          <.th>Current Installation</.th>
          <.th>nickname</.th>
          <.th>Full Name</.th>
          <.th>last Seen</.th>
          <.th>created</.th>
          <.th>updated</.th>
        </tr>
      </thead>

      <%= for user <- @users do %>
        <.tr striped={true}>
          <.td><%= user.id %></.td>
          <.td><.link_to_installation installation={user.current_installation} /></.td>
          <.td>
            <%= link(user.nickname,
              to: Routes.admin_user_path(MrgrWeb.Endpoint, :show, user.id),
              class: "text-teal-700 hover:text-teal-500"
            ) %>
          </.td>
          <.td><%= user.name %></.td>
          <.td><%= ts(user.last_seen_at, @tz) %></.td>
          <.td><%= ts(user.inserted_at, @tz) %></.td>
          <.td><%= ts(user.updated_at, @tz) %></.td>
        </.tr>
      <% end %>
    </table>
    """
  end

  def link_to_installation(%{installation: nil} = assigns) do
    ~H[]
  end

  def link_to_installation(%{installation: %Ecto.Association.NotLoaded{}} = assigns) do
    ~H"""
    <.aside>not loaded</.aside>
    """
  end

  def link_to_installation(assigns) do
    ~H"""
    <.l href={Routes.admin_installation_path(MrgrWeb.Endpoint, :show, @installation.id)}>
      <%= @installation.account.login %>
    </.l>
    """
  end
end
