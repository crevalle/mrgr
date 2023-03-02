defmodule MrgrWeb.OnboardingLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Onboarding

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      subscribe(current_user)

      installation = current_user.current_installation
      stats = stats(installation)

      socket
      |> assign(:installation, installation)
      |> assign(:stats, stats)
      |> put_title("Onboarding")
      |> ok()
    else
      ok(socket)
    end
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 pt-4">
      <div class="flex flex-col space-y-8 lg:w-1/2 md:w-full">
        <.heading title="All Right!👋 Let's get you started" />

        <div class="space-y-4">
          <p>Mrgr onboarding is just 3 simple steps:</p>

          <.step_list>
            <.step name="install_github_app" number={1} installation={@installation} />
            <.step name="sync_data" number={2} installation={@installation} />
            <.step name="done" number={3} installation={@installation} />
          </.step_list>
        </div>

        <div class="flex flex-col space-y-4">
          <.installed_message installation={@installation} />
          <.syncing_message installation={@installation} />
          <.render_stats stats={@stats} />
          <.action installation={@installation} socket={@socket} />
        </div>
      </div>
    </div>
    """
  end

  def subscribe(user) do
    subscribe_to_onboarding_events(user)
    subscribe_to_installation_events(user.current_installation)
  end

  def subscribe_to_onboarding_events(user) do
    user
    |> Mrgr.PubSub.Topic.onboarding()
    |> Mrgr.PubSub.subscribe()
  end

  # first time through
  def subscribe_to_installation_events(nil) do
    :ok
  end

  def subscribe_to_installation_events(installation) do
    installation
    |> Mrgr.PubSub.Topic.installation()
    |> Mrgr.PubSub.subscribe()
  end

  def handle_info(%{event: @installation_created, payload: installation}, socket) do
    # now we can listen for data sync events
    subscribe_to_installation_events(installation)

    # only this user should get this message
    # this attr is set in the installation module, but our in-memory user doesn't get the update
    user = %{
      socket.assigns.current_user
      | current_installation_id: installation.id,
        current_installation: installation
    }

    socket
    |> assign(:current_user, user)
    |> assign(:installation, installation)
    |> noreply()
  end

  def handle_info(%{event: @installation_onboarding_progressed, payload: installation}, socket) do
    socket
    |> assign(:installation, installation)
    |> assign(:stats, stats(installation))
    |> noreply()
  end

  def handle_info(_event, socket), do: noreply(socket)

  def stats(%{state: "onboarding_complete"} = installation) do
    Mrgr.Installation.hot_stats(installation)
  end

  def stats(_), do: %{}
end
