defmodule MrgrWeb.Live.InstallationLoading do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Admin

  @in_progress "in_progress"
  @done "done"

  def mount(_session, params, socket) do
    installation = Mrgr.Installation.find(params["installation_id"])

    Mrgr.PubSub.subscribe_to_installation(installation)

    stats =
      case Mrgr.Installation.data_synced?(installation) do
        true -> compile_stats(installation)
        false -> %{}
      end

    socket
    |> assign(:installation, installation)
    |> assign(:events, [])
    |> assign(:stats, stats)
    |> assign(:done, @done)
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <p>
        Good News!  Mrgr has been installed to the
        <span class="font-bold"><%= @installation.account.login %></span>
        <%= account_type(@installation) %>.  Let's pull in your data...
      </p>

      <div class="flex flex-col space-y-2">
        <%= for event <- @events do %>
          <div class="flex items-center space-x-2">
            <%= if event.status == "in_progress" do %>
              <.spinner id="spinner-members" />
            <% end %>

            <%= if event.status == @done do %>
              🆗
            <% end %>

            <p><%= event.name %></p>
          </div>
        <% end %>

        <%= if Mrgr.Installation.data_synced?(@installation) do %>
          <span class="font-bold">Success!</span>
          <p>We've synced your data.  Here are the stats:</p>

          <table class="w-1/3">
            <tr>
              <td>
                <div class="flex items-center space-x-1">
                  <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />Members
                </div>
              </td>
              <td class="font-semibold"><%= @stats.members %></td>
            </tr>
            <tr>
              <td>
                <div class="flex items-center space-x-1"><.repository_icon />Repositories</div>
              </td>
              <td class="font-semibold"><%= @stats.repositories %></td>
            </tr>
            <tr>
              <td>
                <div class="flex items-center space-x-1">
                  <.icon name="share" class="text-gray-400 mr-1 h-5 w-5" />Pull Requests
                </div>
              </td>
              <td class="font-semibold"><%= @stats.pull_requests %></td>
            </tr>
          </table>

          <.payment_or_activate_button installation={@installation} />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("activate", _params, socket) do
    Mrgr.Installation.activate_user_type_installations(socket.assigns.installation)

    socket
    |> noreply()
  end

  defp translate_state(%{state: "onboarding_members"}), do: "Loading Members"
  defp translate_state(%{state: "onboarding_teams"}), do: "Loading Teams"
  defp translate_state(%{state: "onboarding_repos"}), do: "Loading Repositories"
  defp translate_state(%{state: "onboarding_prs"}), do: "Loading Pull Requests"
  defp translate_state(_), do: ""

  def handle_info(%{event: @installation_onboarding_progressed, payload: installation}, socket) do
    case Mrgr.Installation.data_synced?(installation) do
      true ->
        socket
        |> assign(:installation, installation)
        |> assign(:stats, compile_stats(installation))
        |> assign(:events, complete_events(socket))
        |> noreply()

      false ->
        new_event = %{status: @in_progress, name: translate_state(installation)}
        completed_events = complete_events(socket)

        events = [new_event | completed_events]

        # reverse to keep them chronological
        # ❗️this is borked.  they keep jumping around
        socket
        |> assign(:events, Enum.reverse(events))
        |> noreply()
    end
  end

  def handle_info(%{event: _whatevs}, socket) do
    socket
    |> noreply()
  end

  def complete_events(socket) do
    Enum.map(socket.assigns.events, fn e -> Map.put(e, :status, @done) end)
  end

  defp compile_stats(installation) do
    Mrgr.Installation.hot_stats(installation)
  end

  defp account_type(%{target_type: "User"}), do: "user account"
  defp account_type(_org_or_app), do: "organization"
end
