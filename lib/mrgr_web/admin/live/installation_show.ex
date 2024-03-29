defmodule MrgrWeb.Admin.Live.InstallationShow do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Admin

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"Installation #{@installation.id} - #{@installation.account.login}"} />

      <.l href={Routes.admin_pull_request_path(@socket, :index, @installation.id)}>
        Pull Requests (<%= @open_pr_count %> open)
      </.l>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="mt-1">
            <.installation_table installation={@installation} tz={@timezone} . />
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Account</.h3>
          </div>

          <div class="mt-1">
            <table class="min-w-full">
              <.table_attr obj={@installation.account} key={:avatar_url} . />
              <.table_attr obj={@installation.account} key={:external_id} . />
              <.table_attr obj={@installation.account} key={:login} . />
              <.table_attr obj={@installation.account} key={:type} . />
              <.table_attr obj={@installation.account} key={:url} . />
              <.table_attr obj={@installation.account} key={:updated_at} tz={@timezone} . />
              <.table_attr obj={@installation.account} key={:inserted_at} tz={@timezone} . />
            </table>
          </div>
        </div>
      </div>

      <.subscription subscription={@installation.subscription} tz={@timezone} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Creator</.h3>
          </div>

          <div class="mt-1">
            <.admin_user_table users={[@installation.creator]} tz={@timezone} . />
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Users</.h3>
          </div>

          <div class="mt-1">
            <.admin_user_table users={@installation.users} tz={@timezone} . />
          </div>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <%= live_render(@socket, MrgrWeb.Admin.Live.InstallationMemberTable,
          id: "member-table",
          session: %{"id" => @installation.id}
        ) %>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <.live_component
          module={MrgrWeb.Components.Live.TeamListComponent}
          id="team-list"
          installation_id={@installation.id}
          timezone={@timezone}
        />
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <%= live_render(@socket, MrgrWeb.Admin.Live.InstallationRepoTable,
          id: "repository-table",
          session: %{"id" => @installation.id}
        ) %>
      </div>

      <.slackbot slackbot={@installation.slackbot} />
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      installation = Mrgr.Installation.find_admin(id)
      open_pr_count = Mrgr.PullRequest.open_pr_count(id)

      Mrgr.PubSub.subscribe_to_installation(installation)

      socket
      |> assign(:installation, installation)
      |> assign(:open_pr_count, open_pr_count)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("re-onboard", _params, socket) do
    Mrgr.Installation.queue_initial_setup(socket.assigns.installation)

    socket
    |> Flash.put(:info, "Commencing onboarding")
    |> noreply()
  end

  def handle_info(%{event: @installation_onboarding_progressed, payload: installation}, socket) do
    installation = %{
      socket.assigns.installation
      | state: installation.state,
        state_changes: installation.state_changes
    }

    socket
    |> assign(:installation, installation)
    |> noreply()
  end

  def handle_info(_event, socket), do: noreply(socket)
end
