defmodule MrgrWeb.Components.Live.NotificationPreference do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <tr class="border-t border-gray-300 " id={"preference-#{@preference.id}"}>
      <.td class="rounded-lg"><%= format_preference_name(@preference.event) %></.td>
      <.td>
        <.notification_channels_toggle
          obj={@preference}
          slack_unconnected={@slack_unconnected}
          target={@myself}
        />
      </.td>
    </tr>
    """
  end

  def handle_event("toggle-channel", %{"attr" => attr}, socket) do
    preference =
      socket.assigns.preference
      |> Mrgr.Schema.UserNotificationPreference.toggle_notification(String.to_existing_atom(attr))

    send(self(), {:preference_updated, preference})

    socket
    |> noreply()
  end
end
