defmodule MrgrWeb.OnboardingLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Onboarding

  on_mount MrgrWeb.Plug.Auth

  # @steps %{
  # 0 => :provide_email,
  # 1 => :create_installation,
  # 2 => :sync_data,
  # 3 => :install_slackbot,
  # 4 => :review_notifications,
  # 5 => :done
  # }

  @steps [
    %{number: 0, name: :provide_email},
    %{number: 1, name: :create_installation},
    %{number: 2, name: :sync_data},
    %{number: 3, name: :review_notifications},
    %{number: 4, name: :done}
  ]

  def mount(_params, _session, socket) do
    if connected?(socket) do
      socket = MrgrWeb.Plug.Auth.assign_user_timezone(socket)

      current_user = socket.assigns.current_user
      subscribe(current_user)

      state = compute_state(current_user)

      socket
      |> assign(:state, state)
      |> assign(:changeset, email_changeset(current_user))
      |> put_title("Onboarding")
      |> ok()
    else
      ok(socket)
    end
  end

  def basic_state(current_user) do
    %{
      step: nil,
      user: current_user,
      installation: current_user.current_installation,
      stats: stats(current_user.current_installation)
    }
  end

  # passing in the socket
  def compute_state(%{assigns: %{current_user: user}} = socket) do
    socket
    |> assign(:state, compute_state(user))
  end

  def compute_state(%{email: nil} = current_user) do
    current_user
    |> basic_state()
    |> set_step(:provide_email)
  end

  def compute_state(%{current_installation: nil} = current_user) do
    current_user
    |> basic_state()
    |> set_step(:create_installation)
  end

  def compute_state(%{current_installation: %{slackbot: bot}} = current_user)
      when not is_nil(bot) do
    current_user
    |> basic_state()
    |> set_step(:done)
  end

  # this is out of order because we need to match the full state string
  def compute_state(%{current_installation: %{state: complete}} = current_user)
      when complete in ["onboarding_complete", "onboarding_error"] do
    current_user
    |> basic_state()
    |> set_step(:review_notifications)
  end

  def compute_state(%{current_installation: %{state: "onboarding_" <> _status}} = current_user) do
    current_user
    |> basic_state()
    |> set_step(:sync_data)
  end

  def set_step(state, name) do
    Map.put(state, :step, step_by_name(@steps, name))
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 pt-4">
      <div class="flex flex-col space-y-8 lg:w-1/2 md:w-full">
        <.heading title="All Right!👋 Let's get you started" />

        <%= if @state.step.name == :provide_email do %>
          <div class="flex flex-col space-y-2">
            <h5>Add your Email</h5>
            <p>Looks like Github didn't provide your email address. Please enter one to continue.</p>
            <.form :let={f} for={@changeset} phx-submit="update-email">
              <div class="flex items-center space-x-1">
                <%= text_input(f, :email,
                  placeholder: "you@my_sweet_company.com",
                  class: "w-full text-sm font-medium rounded-md text-gray-700 mt-px pt-2"
                ) %>
                <.button
                  type="submit"
                  phx-disable-with="Saving..."
                  class="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500"
                >
                  Save
                </.button>
              </div>
              <.error form={f} attr={:email} />
            </.form>
          </div>
        <% else %>
          <div class="space-y-4">
            <p>Mrgr onboarding is just 4 simple steps:</p>

            <.step_list state={@state} />
          </div>
        <% end %>
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

  def handle_event("update-email", %{"user" => params}, socket) do
    user = socket.assigns.current_user

    user
    |> email_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, user} ->
        socket
        |> Flash.put(:info, "Thanks! Now to the good stuff.")
        |> assign(:current_user, user)
        |> assign(:state, compute_state(user))
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("notify-via-email", _params, socket) do
    state = set_step(socket.assigns.state, :done)

    Mrgr.Notification.Welcome.send_via_slack(socket.assigns.current_user)

    socket
    |> assign(:state, state)
    |> noreply()
  end

  def handle_event("add-more-alerts", _params, socket) do
    socket
    |> redirect(to: ~p"/high-impact-files")
    |> noreply()
  end

  def handle_event("go-to-dashboard", _params, socket) do
    socket
    |> redirect(to: ~p"/pull-requests")
    |> noreply()
  end

  def email_changeset(user, params \\ %{}) do
    user
    |> Mrgr.Schema.User.email_changeset(params)
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
    |> compute_state()
    |> noreply()
  end

  def handle_info(%{event: @installation_onboarding_progressed, payload: installation}, socket) do
    # basic state is computed off the user's current installation
    # reset it with the latest data from the broadcast
    user = %{
      socket.assigns.current_user
      | current_installation_id: installation.id,
        current_installation: installation
    }

    socket
    |> assign(:current_user, user)
    |> compute_state()
    |> noreply()
  end

  def handle_info(_event, socket), do: noreply(socket)

  def stats(%{state: "onboarding_complete"} = installation) do
    Mrgr.Installation.hot_stats(installation)
  end

  def stats(_), do: %{}

  def done?(%{step: %{name: :done}}), do: true
  def done?(_state), do: false

  def step_by_name(steps, name) do
    Enum.find(steps, fn step -> step.name == name end)
  end
end
