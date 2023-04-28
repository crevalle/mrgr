defmodule MrgrWeb.Admin.Live.RepositoryShow do
  use MrgrWeb, :live_view

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title={"Repository #{@repo.name} - #{@repo.installation.account.login}"} />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="my-1">
            <.h3>High Impact File Rules</.h3>
          </div>

          <div class="mt-1">
            <.table>
              <.th>id</.th>
              <.th>name</.th>
              <.th>pattern</.th>
              <.th>color</.th>
              <.th>source</.th>
              <.th>user</.th>
              <.th>created</.th>
              <.th>updated</.th>
              <tbody>
                <.tr :for={hif <- @repo.high_impact_file_rules}>
                  <.td><%= hif.id %></.td>
                  <.td><%= hif.name %></.td>
                  <.td><%= hif.pattern %></.td>
                  <.td>
                    <div style={"background-color: #{hif.color};"} class="w-5 h-5 rounded-md"></div>
                  </.td>
                  <.td><%= hif.source %></.td>
                  <.td><%= hif.user.nickname %></.td>
                  <.td><%= ts(hif.inserted_at, @tz) %></.td>
                  <.td><%= ts(hif.updated_at, @tz) %></.td>
                </.tr>
              </tbody>
            </.table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      repo = Mrgr.Repository.find_for_admin(id)

      socket
      |> assign(:repo, repo)
      |> ok()
    else
      ok(socket)
    end
  end
end
