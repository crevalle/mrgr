defmodule MrgrWeb.Components.Live.TeamListComponent do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="px-4 py-5 sm:px-6">
      <div class="my-1">
        <.h3>Teams (<%= Enum.count(@teams) %> total)</.h3>
      </div>

      <div class="mt-1">
        <table class="min-w-full">
          <thead class="bg-white">
            <tr>
              <.th>ID</.th>
              <.th>External ID</.th>
              <.th>Node ID</.th>
              <.th>Name</.th>
              <.th>Permission</.th>
              <.th>Privacy</.th>
              <.th>URL</.th>
              <.th>Updated</.th>
              <.th>Created</.th>
            </tr>
          </thead>

          <.tr :for={team <- @teams} striped={true}>
            <.td><%= team.id %></.td>
            <.td><%= team.external_id %></.td>
            <.td><%= team.node_id %></.td>
            <.td><%= team.name %></.td>
            <.td><%= team.permission %></.td>
            <.td><%= team.privacy %></.td>
            <.td><%= team.url %></.td>
            <.td><%= ts(team.updated_at, @timezone) %></.td>
            <.td><%= ts(team.inserted_at, @timezone) %></.td>
          </.tr>
        </table>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    teams = Mrgr.Team.for_installation(assigns.installation_id)

    socket
    |> assign(assigns)
    |> assign(:teams, teams)
    |> ok()
  end
end
