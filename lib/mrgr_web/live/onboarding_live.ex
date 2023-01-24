defmodule MrgrWeb.OnboardingLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Onboarding

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      subscribe(current_user)

      ### These states are DIFFERENT from installation states.
      #
      # we don't pull directly from the installation's state
      # because of the initial scenario where the user has not installed
      # the github app, and thus has no installation.  This scenario is
      # the state "new"
      #
      ###
      state = state(current_user.current_installation)

      socket
      |> assign(:state, state)
      |> assign(:installation, current_user.current_installation)
      |> ok()
    else
      ok(socket)
    end
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 pt-4">
      <div class="flex flex-col space-y-8 md:w-2/3 sm:w-full">
        <.heading title="All Right!👋 Let's get you started" />

        <div class="space-y-4">
          <p>Mrgr onboarding is just 4 simple steps:</p>

          <.step_list>
            <.step name="install_github_app" state={@state} />
            <.step name="sync_data" state={@state} />
            <.step name="create_subscription" state={@state} />
            <.step name="done" state={@state} />
          </.step_list>
        </div>

        <.action state={@state} installation={@installation} socket={@socket} />
      </div>
    </div>
    """
  end

  def subscribe(user) do
    user
    |> installation_topic()
    |> Mrgr.PubSub.subscribe()
  end

  def installation_topic(user) do
    Mrgr.PubSub.Topic.installation(user)
  end

  def handle_info(%{event: event, payload: installation}, socket)
      when event in [@installation_initial_sync_completed, @installation_activated] do
    socket
    |> assign(:installation, installation)
    |> assign(:state, state(installation))
    |> noreply()
  end

  def handle_info(_event, socket), do: noreply(socket)

  def state(nil), do: "new"
  def state(installation), do: installation.state
end
