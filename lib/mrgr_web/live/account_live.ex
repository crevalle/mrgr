defmodule MrgrWeb.AccountLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(params, _session, socket) do
    if connected?(socket) do
      installations = Mrgr.Installation.find_for_account_page(socket.assigns.current_user.id)

      subscribe(socket.assigns.current_user)

      socket
      |> put_title("Your Account")
      |> maybe_congratulate_subscription(params)
      |> assign(:installations, installations)
      |> ok()
    else
      ok(socket)
    end
  end

  def maybe_congratulate_subscription(socket, %{"subscription_complete" => _}) do
    socket
    |> Flash.put(:info, "Subscription Activated!")
  end

  def maybe_congratulate_subscription(socket, _), do: socket

  def handle_event("switch-installation", %{"id" => id}, socket) do
    i = Mrgr.List.find(socket.assigns.installations, id)
    user = Mrgr.User.set_current_installation(socket.assigns.current_user, i)

    socket
    |> assign(:current_user, user)
    |> noreply()
  end

  def format_subscription_state(%{subscription_state: "trial"}), do: "Trial"
  def format_subscription_state(%{subscription_state: "active"}), do: "Active"
  def format_subscription_state(%{subscription_state: "cancelled"}), do: "Cancelled"
  def format_subscription_state(%{subscription_state: "personal"}), do: "Free - Personal Account"

  def payment_url(installation, user) do
    base_url = Application.get_env(:mrgr, :payments)[:url]

    "#{base_url}?client_reference_id=#{installation.id}&prefilled_email=#{user_email(user)}"
  end

  def user_email(%{email: nil}), do: nil

  def user_email(%{email: email}) do
    URI.encode_www_form(email)
  end

  def subscribe(user) do
    user
    |> Mrgr.PubSub.Topic.installation()
    |> Mrgr.PubSub.subscribe()
  end

  def handle_info(%{event: @installation_subscription_updated, payload: installation}, socket) do
    socket =
      case Mrgr.Installation.subscribed?(installation) do
        true ->
          Flash.put(socket, :info, "Thanks for subscribing! 🍾")

        false ->
          socket
      end

    socket
    |> assign(:installation, installation)
    |> noreply()
  end

  def handle_info(_event, socket), do: noreply(socket)

  def show_payment_button(%{id: id}, %{creator_id: id} = installation) do
    Mrgr.Installation.trial_period?(installation)
  end

  def show_payment_button(_non_admin_user, _installation), do: false
end
