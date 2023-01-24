defmodule MrgrWeb.Live.InstallationLoading do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Admin

  @in_progress "in_progress"
  @done "done"

  def mount(_session, params, socket) do
    installation = Mrgr.Installation.find(params["installation_id"])

    Mrgr.PubSub.subscribe_to_installation(installation)

    Mrgr.Installation.queue_initial_setup(installation)

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

  defp translate_event(pubsub_event) do
    names = %{
      @installation_loading_members => "Loading Members",
      @installation_loading_repositories => "Loading Repositories",
      @installation_loading_pull_requests => "Loading Pull Request Data"
    }

    # no default, since our handle_info guards against what events it receives
    Map.get(names, pubsub_event)
  end

  def handle_info(%{event: loading_event, payload: _installation}, socket)
      when loading_event in [
             @installation_loading_members,
             @installation_loading_repositories,
             @installation_loading_pull_requests
           ] do
    new_event = %{status: @in_progress, name: translate_event(loading_event)}
    completed_events = complete_events(socket)

    events = [new_event | completed_events]

    # reverse to keep them chronological
    socket
    |> assign(:events, Enum.reverse(events))
    |> noreply()
  end

  def handle_info(%{event: @installation_initial_sync_completed, payload: installation}, socket) do
    socket
    |> assign(:installation, installation)
    |> assign(:stats, compile_stats(installation))
    |> assign(:events, complete_events(socket))
    |> noreply()
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
