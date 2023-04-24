defmodule MrgrWeb.Components.Admin do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core
  alias Phoenix.LiveView.JS

  def slackbot(%{slackbot: nil} = assigns) do
    ~H"""
    <.section>
      <:title>
        Slackbot
      </:title>

      <p class="italic">No slack integration!</p>
    </.section>
    """
  end

  def slackbot(assigns) do
    ~H"""
    <.section>
      <:title>
        Slackbot
      </:title>

      <table class="w-full">
        <.table_attr obj={@slackbot} key={:access_token} . />
        <.table_attr obj={@slackbot} key={:app_id} . />
        <.tr striped={true}>
          <.td class="font-bold">Authed User Id</.td>
          <.td><%= @slackbot.authed_user["id"] %></.td>
        </.tr>
        <.table_attr obj={@slackbot} key={:bot_user_id} . />
        <.table_attr obj={@slackbot} key={:enterprise} . />
        <.table_attr obj={@slackbot} key={:is_enterprise_install} . />
        <.table_attr obj={@slackbot} key={:scope} . />
        <.tr striped={true}>
          <.td class="font-bold">Team ID</.td>
          <.td><%= @slackbot.team["id"] %></.td>
        </.tr>
        <.tr striped={true}>
          <.td class="font-bold">Team Name</.td>
          <.td><%= @slackbot.team["name"] %></.td>
        </.tr>
        <.table_attr obj={@slackbot} key={:token_type} . />
      </table>
    </.section>
    """
  end

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

  def notification_preference_table(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <h5>User Notification Preferences</h5>
      <.table>
        <.th>id</.th>
        <.th>event</.th>
        <.th>send email</.th>
        <.th>send slack</.th>
        <.th>Updated</.th>
        <.tr>
          <.td><%= @preference.id %></.td>
          <.td><%= @preference.event %></.td>
          <.td><%= tf(@preference.email) %></.td>
          <.td><%= tf(@preference.slack) %></.td>
          <.td><%= ts(@preference.updated_at, @timezone) %></.td>
        </.tr>
      </.table>
    </div>
    """
  end

  def notification_address_table(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <h5>User Notification Addresses</h5>
      <.table>
        <.th>id</.th>
        <.th>email</.th>
        <.th>slack id</.th>
        <.th>updated</.th>
        <.tr>
          <.td><%= @address.id %></.td>
          <.td><%= @address.email %></.td>
          <.td><%= @address.slack_id %></.td>
          <.td><%= ts(@address.updated_at, @timezone) %></.td>
        </.tr>
      </.table>
    </div>
    """
  end

  def installation_table(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <div class="flex justify-between">
        <div class="flex flex-col">
          <h5>
            <.l href={@installation.html_url}>
              <%= account_name(@installation) %>
            </.l>
          </h5>
          <p class="text-sm text-gray-500 italic">
            <%= @installation.target_type %> <%= @installation.target_id %>
          </p>
        </div>
        <div class="flex flex-col">
          <p class="text-sm text-gray-500">Created: <%= ts(@installation.inserted_at, @tz) %></p>
          <p class="text-sm text-gray-500">Updated: <%= ts(@installation.updated_at, @tz) %></p>
        </div>
      </div>
      <.table>
        <.th></.th>
        <.th>Onboarding</.th>
        <.th>Subscription</.th>
        <.tr>
          <.td class="font-bold">State</.td>
          <.td>
            <%= @installation.state %>
            <.l
              :if={!Mrgr.Installation.onboarded?(@installation)}
              phx-click={JS.push("re-onboard", value: %{id: @installation.id})}
              data-confirm="Sure about that?"
            >
              Re-onboard
            </.l>
          </.td>
          <.td><%= @installation.subscription_state %></.td>
        </.tr>

        <.tr>
          <.td class="font-bold">State Changes</.td>
          <.td>
            <table>
              <.tr :for={sc <- Enum.reverse(@installation.state_changes)}>
                <td><%= sc.state %></td>
                <td><%= sc.transitioned_at %></td>
              </.tr>
            </table>
          </.td>
          <.td>
            <table>
              <.tr :for={sc <- Enum.reverse(@installation.subscription_state_changes)}>
                <td><%= sc.state %></td>
                <td><%= sc.transitioned_at %></td>
              </.tr>
            </table>
          </.td>
        </.tr>
        <.tr>
          <.td class="font-bold">Error</.td>
          <.td><%= @installation.onboarding_error %></.td>
          <.td></.td>
        </.tr>
      </.table>
      <.table>
        <.th>Access Token</.th>
        <.th>Expires</.th>
        <.tr>
          <.td>
            <.l href={@installation.access_tokens_url}>
              <%= @installation.token %>
            </.l>
          </.td>
          <.td>
            <%= ts(@installation.token_expires_at, @tz) %>
          </.td>
        </.tr>
      </.table>
      <.table>
        <.th>Events</.th>
        <.th>Permissions</.th>
        <.th>Repos</.th>
        <.tr class="align-top">
          <.td>
            <ul>
              <li :for={event <- @installation.events}>
                <%= event %>
              </li>
            </ul>
          </.td>
          <.td>
            <ul>
              <li :for={{k, v} <- @installation.permissions}>
                <span class="text-sm text-gray-500"><%= k %></span>
                <span class="font-semibold"><%= v %></span>
              </li>
            </ul>
          </.td>
          <.td><%= @installation.repository_selection %></.td>
        </.tr>
      </.table>

      <.table>
        <.th>Events</.th>
        <.th>Permissions</.th>
        <.th>Repos</.th>
        <.tr>
          <.td>
            <ul>
              <li :for={event <- @installation.events}>
                <%= event %>
              </li>
            </ul>
          </.td>
          <.td>
            <ul>
              <li :for={{k, v} <- @installation.permissions}>
                <span class="text-sm text-gray-500"><%= k %></span>
                <span class="font-semibold"><%= v %></span>
              </li>
            </ul>
          </.td>
          <.td><%= @installation.repository_selection %></.td>
        </.tr>
      </.table>
    </div>
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
