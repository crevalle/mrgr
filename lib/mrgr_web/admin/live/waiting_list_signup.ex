defmodule MrgrWeb.Admin.Live.WaitingListSignup do
  use MrgrWeb, :live_view

  require Ecto.Query

  on_mount {MrgrWeb.Plug.Auth, :admin}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      signups =
        Mrgr.Schema.WaitingListSignup
        |> Ecto.Query.order_by(desc: :inserted_at)
        |> Mrgr.Repo.all()

      {:ok, assign(socket, :signups, signups)}
    else
      {:ok, assign(socket, :signups, [])}
    end
  end

  def render(assigns) do
    ~H"""
    <.heading title="Waiting List Signups" />

    <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <div class="mt-1">
          <table class="min-w-full">
            <thead class="bg-white">
              <tr>
                <.th uppercase={true}>ID</.th>
                <.th uppercase={true}>email</.th>
                <.th uppercase={true}>updated</.th>
                <.th uppercase={true}>created</.th>
              </tr>
            </thead>

            <%= for signup <- @signups do %>
              <.tr striped={true}>
                <.td><%= signup.id %></.td>
                <.td><%= signup.email %></.td>
                <.td><%= ts(signup.updated_at, @timezone) %></.td>
                <.td><%= ts(signup.inserted_at, @timezone) %></.td>
              </.tr>
            <% end %>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
