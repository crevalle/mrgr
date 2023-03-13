defmodule MrgrWeb.AccountLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      installations = Mrgr.Installation.find_for_account_page(socket.assigns.current_user.id)

      subscribe(socket.assigns.current_user)

      socket
      |> put_title("Your Account")
      |> assign(:installations, installations)
      |> assign(:selected_installation, nil)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("switch-installation", %{"id" => id}, socket) do
    i = Mrgr.List.find(socket.assigns.installations, id)
    user = Mrgr.User.set_current_installation(socket.assigns.current_user, i)

    socket
    |> assign(:current_user, user)
    |> noreply()
  end

  def handle_event("show-detail", %{"id" => id}, socket) do
    installation = Mrgr.List.find(socket.assigns.installations, id)

    socket
    |> assign(:selected_installation, installation)
    |> noreply()
  end

  def handle_event("close-detail", _params, socket) do
    socket
    |> assign(:selected_installation, nil)
    |> noreply()
  end

  def handle_event("invite-users", %{"users" => %{"emails" => emails}}, socket) do
    emails
    |> format_raw_email_input()
    |> Mrgr.User.invite_by_email(socket.assigns.selected_installation)

    socket
    |> Flash.put(:info, "Invitations sent!")
    |> assign(:selected_installation, nil)
    |> noreply()
  end

  defp format_raw_email_input(string) do
    string
    |> String.replace("\r\n", ",")
    |> String.replace("\n", ",")
    |> String.replace(" ", ",")
    |> String.split(",")
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&looks_like_an_email/1)
  end

  def looks_like_an_email(string) do
    with true <- String.contains?(string, "@"),
         true <- String.contains?(string, ".") do
      true
    else
      false -> false
    end
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
