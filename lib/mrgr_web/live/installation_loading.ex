defmodule MrgrWeb.Live.InstallationLoading do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(session, params, socket) do
    set_dot_clock()

    installation = Mrgr.Installation.find(params["installation_id"])

    check_installation_already_set_up()

    Mrgr.PubSub.subscribe_to_installation(installation)

    socket
    |> assign(:installation, installation)
    |> assign(:dots, cycle_dots())
    |> assign(:events, [])
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col mt-8 space-y-4">
      <p>
        Alright!  Mrgr has been installed to the
        <span class="font-bold"><%= @installation.account.login %></span>
        organization.
      </p>

      <p>
        We are currently syncing all of your data.  When that's done, you'll be automatically redirected to get started. 🙂
      </p>

      <div class="flex flex-col space-y-4">
        <p><%= @dots %></p>

        <%= for event <- @events do %>
          <p class="text-gray-500"><%= event %></p>
        <% end %>
      </div>
    </div>
    """
  end

  def set_dot_clock do
    Process.send_after(self(), "cycle_dots", 100)
  end

  def check_installation_already_set_up do
    # maybe the installation has already been set up by the time the liveview loads
    # and we will thus never get a broadcast message.  if that's so, wait a few
    # seconds after page load to make the user think we are Working Very Hard.

    Process.send_after(self(), "installation_already_set_up", 3000)
  end

  defp translate_event(pubsub_event) do
    names = %{
      @installation_loading_members => "Loading Members...",
      @installation_loading_repositories => "Loading Repositories...",
      @installation_loading_pull_requests => "Loading Pull Request Data..."
    }

    # no default, since our handle_info guards against what events it receives
    Map.get(names, pubsub_event)
  end

  def handle_info("installation_already_set_up", socket) do
    case socket.assigns.installation.setup_completed do
      true ->
        socket
        |> assign(:dots, "OK!")
        |> redirect(to: Routes.pull_request_path(MrgrWeb.Endpoint, :index))
        |> noreply()

      false ->
        socket
        |> noreply()
    end
  end

  def handle_info("cycle_dots", socket) do
    dots = cycle_dots(socket.assigns.dots)

    set_dot_clock()

    socket
    |> assign(:dots, dots)
    |> noreply()
  end

  def handle_info(%{event: loading_event, payload: _installation}, socket)
      when loading_event in [
             @installation_loading_members,
             @installation_loading_repositories,
             @installation_loading_pull_requests
           ] do
    event = translate_event(loading_event)

    events = [event | socket.assigns.events]

    # reverse to keep them chronological
    socket
    |> assign(:events, Enum.reverse(events))
    |> noreply()
  end

  def handle_info(%{event: @installation_setup_completed, payload: _installation}, socket) do
    socket
    |> assign(:dots, "OK!")
    |> redirect(to: Routes.pull_request_path(MrgrWeb.Endpoint, :index))
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket) do
    socket
    |> noreply()
  end

  def cycle_dots(), do: "Syncing "
  def cycle_dots("Syncing "), do: "Syncing ."
  def cycle_dots("Syncing ."), do: "Syncing .."
  def cycle_dots("Syncing .."), do: "Syncing ..."
  def cycle_dots("Syncing ..."), do: "Syncing ...."
  def cycle_dots("Syncing ...."), do: "Syncing "
end
