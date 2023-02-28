defmodule MrgrWeb.Admin.Live.UserShow do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Admin

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"User #{@user.nickname}"} />

      <p>
        <%= img_tag(@user.image, class: "rounded-md") %>
      </p>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="mt-1">
            <table class="min-w-full">
              <.table_attr obj={@user} key={:id} . />
              <.table_attr obj={@user} key={:nickname} . />
              <.table_attr obj={@user} key={:birthday} . />
              <.table_attr obj={@user} key={:email} . />
              <.table_attr obj={@user} key={:notification_email} . />
              <.table_attr obj={@user} key={:name} . />
              <.table_attr obj={@user} key={:first_name} . />
              <.table_attr obj={@user} key={:last_name} . />
              <.table_attr obj={@user} key={:location} . />
              <.table_attr obj={@user} key={:node_id} . />
              <.table_attr obj={@user} key={:avatar_url} . />
              <.table_attr obj={@user} key={:phone} . />
              <.table_attr obj={@user} key={:send_weekly_summary_email} . />
              <.table_attr obj={@user} key={:refresh_token} . />
              <.table_attr obj={@user} key={:token} . />
              <.table_attr obj={@user} key={:token_expires_at} tz={@timezone} . />
              <.table_attr obj={@user} key={:token_updated_at} tz={@timezone} . />
              <.table_attr obj={@user} key={:updated_at} tz={@timezone} . />
              <.table_attr obj={@user} key={:inserted_at} tz={@timezone} . />
            </table>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Member</.h3>
          </div>

          <div class="mt-1">
            <%= if @user.member do %>
              <table class="min-w-full">
                <.table_attr obj={@user.member} key={:login} . />
                <.table_attr obj={@user.member} key={:type} . />
                <.table_attr obj={@user.member} key={:site_admin} . />
                <.table_attr obj={@user.member} key={:node_id} . />
                <.table_attr obj={@user.member} key={:url} . />
                <.table_attr obj={@user.member} key={:avatar_url} . />
                <.table_attr obj={@user.member} key={:events_url} . />
                <.table_attr obj={@user.member} key={:followers_url} . />
                <.table_attr obj={@user.member} key={:following_url} . />
                <.table_attr obj={@user.member} key={:gists_url} . />
                <.table_attr obj={@user.member} key={:gravatar_id} . />
                <.table_attr obj={@user.member} key={:html_url} . />
                <.table_attr obj={@user.member} key={:organizations_url} . />
                <.table_attr obj={@user.member} key={:received_events_url} . />
                <.table_attr obj={@user.member} key={:starred_url} . />
                <.table_attr obj={@user.member} key={:subscriptions_url} . />
              </table>
            <% else %>
              No Member for user!
            <% end %>
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Current Installation</.h3>
          </div>

          <%= if @user.current_installation do %>
            <.installation_table installation={@user.current_installation} tz={@timezone} . />
          <% else %>
            none!
          <% end %>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>All Installations</.h3>
          </div>

          <%= for _install <- @user.installations do %>
            <.installation_table installation={@user.current_installation} tz={@timezone} . />
          <% end %>
        </div>
      </div>

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
end
