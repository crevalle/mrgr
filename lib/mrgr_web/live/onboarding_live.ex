defmodule MrgrWeb.OnboardingLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Onboarding

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      subscribe(current_user)

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
      <div class="flex flex-col space-y-8">
        <.heading title="All Right!👋 Let's get you started" />

        <div class="space-y-4">
          <p>Mrgr onboarding is just 4 simple steps:</p>

          <ol>
            <.step name="install_github_app" state={@state} />
            <.step name="sync_data" state={@state} />
            <li>Create your Subscription 💸</li>
            <li>Get to work!</li>
          </ol>
        </div>

        <div class="flex flex-col space-y-4">
          <div class="w-1/2 p-4 shadow ring-1 ring-black ring-opacity-5 rounded-lg">
            <.action state={@state} installation={@installation} socket={@socket} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def install_github_app?(nil), do: true
  def install_github_app?(_installation), do: false

  def subscribe(user) do
    user
    |> installation_topic()
    |> Mrgr.PubSub.subscribe()
  end

  def installation_topic(user) do
    Mrgr.PubSub.Topic.installation(user)
  end

  def state(nil), do: "new"
  def state(installation), do: installation.state
end
