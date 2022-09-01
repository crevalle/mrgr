defmodule MrgrWeb.Admin.Live.User do
  use MrgrWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title="Users" />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">

          <div class="mt-1">

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
                  <.td><%= link user.id, to: Routes.admin_user_path(@socket, :show, user.id), class: "text-teal-500" %></.td>
                  <.td><%= current_account(user) %></.td>
                  <.td><%= user.nickname %></.td>
                  <.td><%= user.name %></.td>
                  <.td><%= ts(user.last_seen_at, assigns.timezone) %></.td>
                  <.td><%= ts(user.inserted_at, assigns.timezone) %></.td>
                  <.td><%= ts(user.updated_at, assigns.timezone) %></.td>
                </.tr>
              <% end %>
            </table>


          </div>

        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      users = Mrgr.User.all()
      {:ok, assign(socket, :users, users)}
    else
      {:ok, assign(socket, :users, [])}
    end
  end

  defp current_account(%{current_installation: %{account: %{login: login}}}), do: login
  defp current_account(user), do: user.current_installation_id
end
