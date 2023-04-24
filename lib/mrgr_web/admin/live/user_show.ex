defmodule MrgrWeb.Admin.Live.UserShow do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Admin

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between">
        <div class="flex flex-col">
          <div class="flex items-center">
            <.h1><%= @user.nickname %></.h1>
            <%= img_tag(@user.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
          </div>
          <p class="text-sm text-gray-500"><%= @user.name %></p>
          <p class="text-sm text-gray-500"><%= @user.email %></p>
          <p class="text-sm text-gray-500"><%= @user.location %></p>
          <p class="text-sm text-gray-500">Member Node ID: <%= @user.node_id %></p>
        </div>
        <div class="flex flex-col">
          <p class="text-sm text-gray-500">Created: <%= ts(@user.inserted_at, @tz) %></p>
          <p class="text-sm text-gray-500">Updated: <%= ts(@user.updated_at, @tz) %></p>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 flex-col space-y-4">
          <table class="min-w-full">
            <.table_attr obj={@user} key={:notification_email} . />
            <.table_attr obj={@user} key={:send_weekly_changelog_email} . />
          </table>
          <.table>
            <.th>Access Token</.th>
            <.th>Refresh Token</.th>
            <.th>Expires</.th>
            <.th>Updated</.th>
            <.tr>
              <.td><%= @user.token %></.td>
              <.td><%= @user.refresh_token %></.td>
              <.td><%= ts(@user.token_expires_at, @timezone) %></.td>
              <.td><%= ts(@user.token_updated_at, @timezone) %></.td>
            </.tr>
          </.table>

          <div :if={!@user.member}>
            <p class="font-semibold italic">no member for user!</p>
          </div>

          <div :if={@user.member}>
            <h5>Member</h5>
            <.table>
              <.th>id</.th>
              <.th>login</.th>
              <.th>type</.th>
              <.th>site admin</.th>
              <.th>Expires</.th>
              <.th>Updated</.th>
              <.tr>
                <.td><%= @user.member.id %></.td>
                <.td>
                  <.l href={@user.member.html_url}>
                    <.avatar member={@user.member} />
                  </.l>
                </.td>
                <.td><%= @user.member.type %></.td>
                <.td><%= tf(@user.member.site_admin) %></.td>
                <.td><%= ts(@user.member.updated_at, @timezone) %></.td>
                <.td><%= ts(@user.member.inserted_at, @timezone) %></.td>
              </.tr>
            </.table>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 flex flex-col space-y-4">
          <div class="my-1 text-center">
            <.h3>Current Installation</.h3>
          </div>

          <%= if @user.current_installation do %>
            <.installation_table installation={@user.current_installation} tz={@timezone} . />

            <.slack_connection_status connected={
              Mrgr.Installation.slack_connected?(@user.current_installation)
            } />

            <.notification_address_table
              address={find_address(@user, @user.current_installation)}
              timezone={@timezone}
              }
            />

            <.notification_preference_table
              preference={find_preference(@user, @user.current_installation)}
              timezone={@timezone}
              }
            />
          <% else %>
            none!
          <% end %>
        </div>
      </div>

      <.h3>All Installations</.h3>
      <%= for install <- @user.installations do %>
        <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
          <div class="px-4 py-5 flex flex-col space-y-4">
            <.installation_table installation={install} tz={@timezone} . />

            <.slack_connection_status connected={Mrgr.Installation.slack_connected?(install)} />

            <.notification_address_table
              address={find_address(@user, install)}
              timezone={@timezone}
              }
            />

            <.notification_preference_table
              preference={find_preference(@user, install)}
              timezone={@timezone}
              }
            />
          </div>
        </div>
      <% end %>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>URLS</.h3>
          </div>

          <pre>
            <%= render_struct(@user.urls) %>
          </pre>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    user = Mrgr.User.find_full(id)

    socket
    |> assign(user: user)
    |> put_title("Admin - User #{user.id}")
    |> ok
  end

  def find_address(user, installation) do
    Enum.find(user.notification_addresses, &(&1.installation_id == installation.id))
  end

  def find_preference(user, installation) do
    Enum.find(user.notification_preferences, &(&1.installation_id == installation.id))
  end
end
