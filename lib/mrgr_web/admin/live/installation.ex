defmodule MrgrWeb.Admin.Live.Installation do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <.heading title="Installations" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="mt-1">
          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th uppercase={true}>ID</.th>
                <.th uppercase={true}>App ID</.th>
                <.th uppercase={true}>App Slug</.th>
                <.th uppercase={true}>Type</.th>
                <.th uppercase={true}>Creator</.th>
                <.th uppercase={true}>Account</.th>
                <.th uppercase={true}>Actions</.th>
                <.th uppercase={true}>Onboarding Status</.th>
                <.th uppercase={true}>Repositories</.th>
                <.th uppercase={true}>Updated</.th>
                <.th uppercase={true}>Created</.th>
              </tr>
            </thead>

            <%= for i <- @installations do %>
              <.tr striped={true}>
                <.td>
                  <%= link(i.id,
                    to: Routes.admin_installation_path(MrgrWeb.Endpoint, :show, i.id),
                    class: "text-teal-700 hover:text-teal-500"
                  ) %>
                </.td>
                <.td><%= i.app_id %></.td>
                <.td><%= i.app_slug %></.td>
                <.td><%= i.target_type %></.td>
                <.td><%= i.creator.nickname %></.td>
                <.td><%= i.account.login %></.td>
                <.td>
                  <.outline_button
                    phx-click={JS.push("refresh-prs", value: %{installation_id: i.id})}
                    class="border-teal-700 text-teal-700 hover:text-teal-500"
                  >
                    Refresh PRs
                  </.outline_button>
                </.td>
                <.td><%= i.state %></.td>
                <.td><%= Enum.count(i.repositories) %></.td>
                <.td><%= ts(i.updated_at, assigns.timezone) %></.td>
                <.td><%= ts(i.inserted_at, assigns.timezone) %></.td>
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
      # subscribe()

      installations = Mrgr.Installation.all_admin()
      {:ok, assign(socket, :installations, installations)}
    else
      {:ok, socket}
    end
  end

  def handle_event("refresh-prs", %{"installation_id" => id}, socket) do
    Task.start(fn ->
      installation = Mrgr.Installation.find(id) |> Mrgr.Repo.preload(:repositories)
      Mrgr.Installation.refresh_pull_requests!(installation)
    end)

    socket
    |> Flash.put(:info, "Refreshing")
    |> noreply()
  end

  # def subscribe do
  # Mrgr.PubSub.subscribe(Mrgr.PubSub.Topic.admin())
  # end

  # # ignore other messages
  # def handle_info(%{event: _}, socket), do: {:noreply, socket}
end
