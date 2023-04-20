defmodule MrgrWeb.Components.Live.UserHIF do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <tr class="border-t border-gray-300">
      <.td>
        <.hif_pattern pattern={@hif.pattern} />
      </.td>
      <.td>
        <.badge item={@hif} />
      </.td>
      <.td>
        <.notification_channels_toggle
          obj={@hif}
          slack_unconnected={@slack_unconnected}
          target={@myself}
        />
      </.td>
    </tr>
    """
  end

  def handle_event("toggle-channel", %{"attr" => attr}, socket) do
    hif =
      socket.assigns.hif
      |> Mrgr.HighImpactFileRule.toggle_notification(String.to_existing_atom(attr))

    send(self(), {:hif_updated, hif})

    socket
    |> noreply()
  end
end
