defmodule MrgrWeb.AccountLive do
  use MrgrWeb, :live_view

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
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
end
