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
            <.step name="install_github_app" installation={@installation} />
            <.step name="done" installation={@installation} />
          </.step_list>
        </div>

        <.installed_message installation={@installation} />
        <.render_stats stats={@stats} />
        <.action installation={@installation} socket={@socket} />
      </div>
    </div>
    """
  end

  def subscribe(%{current_installation_id: nil} = user) do
    user
    |> Mrgr.PubSub.Topic.onboarding()
    |> Mrgr.PubSub.subscribe()
  end

  def subscribe(user_or_installation) do
    user_or_installation
    |> Mrgr.PubSub.Topic.installation()
    |> Mrgr.PubSub.subscribe()
  end

  def handle_info(%{event: @installation_created, payload: installation}, socket) do
    # now we can listen for data sync events
    subscribe(installation)

    # only this user should get this message
    user = %{socket.assigns.current_user | current_installation_id: installation.id}

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
