defmodule MrgrWeb.Admin.Live.InstallationShow do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"Installation #{@installation.id}"} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">

          <div class="mt-1">
            <.installation_table installation={@installation} tz={@timezone} ./>
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
              <.table_attr obj={@installation.account} key={:avatar_url} ./>
              <.table_attr obj={@installation.account} key={:external_id} ./>
              <.table_attr obj={@installation.account} key={:login} ./>
              <.table_attr obj={@installation.account} key={:type} ./>
              <.table_attr obj={@installation.account} key={:url} ./>
              <.table_attr obj={@installation.account} key={:updated_at} tz={@timezone} ./>
              <.table_attr obj={@installation.account} key={:inserted_at} tz={@timezone} ./>
            </table>
          </div>

        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Users</.h3>
          </div>

          <div class="mt-1">
            <.admin_user_table users={@installation.users} tz={@timezone} ./>
          </div>

        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>Repositories</.h3>
          </div>

          <div class="mt-1">
            <.admin_repository_table repositories={@installation.repositories} tz={@timezone} ./>
          </div>

        </div>
      </div>
    </div>

    """
  end

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      # subscribe()

      installation = Mrgr.Installation.find_admin(id)
      {:ok, assign(socket, :installation, installation)}
    else
      {:ok, socket}
    end
  end

  # def subscribe do
  # Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())
  # end

  # # ignore other messages
  # def handle_info(%{event: _}, socket), do: {:noreply, socket}
end
