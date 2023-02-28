defmodule MrgrWeb.AccountLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe(socket.assigns.current_user)

      socket
      |> put_title("Your Account")
      |> assign(:installation, socket.assigns.current_user.current_installation)
      |> ok()
    else
      ok(socket)
    end
  end

  def format_subscription_state(%{subscription_state: "trial"}), do: "Trial"
  def format_subscription_state(%{subscription_state: "active"}), do: "Active"
  def format_subscription_state(%{subscription_state: "cancelled"}), do: "Cancelled"
  def format_subscription_state(%{subscription_state: "personal"}), do: "Free - Personal Account"

  def payment_url(installation, user) do
    base_url = Application.get_env(:mrgr, :payments)[:url]

    "#{base_url}?client_reference_id=#{installation.id}&prefilled_email=#{URI.encode_www_form(user.email)}"
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
end
