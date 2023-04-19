defmodule MrgrWeb.Components.Live.NotificationPreference do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    disable_slack = !Mrgr.Installation.slack_connected?(assigns.current_user.current_installation)

    socket
    |> assign(assigns)
    |> assign(:disable_slack, disable_slack)
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <tr class="border-t border-gray-300 " id={"preference-#{@preference.id}"}>
      <.td class="rounded-lg py-2"><%= format_preference_name(@preference.event) %></.td>
      <.td class="text-center py-2">
        <.form :let={f} for={%{}} as={:preference} phx-change="update" phx-target={@myself}>
          <%= checkbox(f, :email,
            value: @preference.email,
            class: "checkbox"
          ) %>
        </.form>
      </.td>
      <.td class="text-center rounded-lg py-2">
        <.form :let={f} for={%{}} as={:preference} phx-change="update" phx-target={@myself}>
          <%= checkbox(f, :slack,
            value: @preference.slack,
            class: "checkbox",
            disabled: @disable_slack
          ) %>
        </.form>
      </.td>
    </tr>
    """
  end

  def handle_event("update", %{"preference" => params}, socket) do
    preference =
      socket.assigns.preference
      |> Mrgr.Schema.UserNotificationPreference.changeset(params)
      |> Mrgr.Repo.update!()

    socket
    |> assign(:preference, preference)
    |> Flash.put(:info, "Preferences updated!")
    |> noreply()
  end
end
