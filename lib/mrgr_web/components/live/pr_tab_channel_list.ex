defmodule MrgrWeb.Components.Live.PRTabChannelList do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <tr class="border-t border-gray-300" id={"@tab-#{@tab.id}"}>
      <.td class="rounded-lg"><%= @tab.title %></.td>
      <.td>
        <.notification_channels_toggle
          obj={@tab}
          slack_unconnected={@slack_unconnected}
          target={@myself}
        />
      </.td>
    </tr>
    """
  end

  def handle_event("toggle-channel", %{"attr" => attr}, socket) do
    tab =
      socket.assigns.tab
      |> Mrgr.Schema.PRTab.toggle_channel(String.to_existing_atom(attr))

    send(self(), {:tab_updated, tab})

    socket
    |> noreply()
  end
end
