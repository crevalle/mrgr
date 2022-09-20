defmodule MrgrWeb.Admin.Live.User do
  use MrgrWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title="Users" />

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">

          <div class="mt-1">
            <.admin_user_table users={@users} tz={@timezone} ./>
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
end
