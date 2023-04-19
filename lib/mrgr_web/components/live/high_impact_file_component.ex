defmodule MrgrWeb.Components.Live.HighImpactFileComponent do
  use MrgrWeb, :live_component

  def handle_event("toggle-channel", %{"id" => id, "attr" => attr}, socket) do
    hif =
      socket.assigns.repo.high_impact_file_rules
      |> Mrgr.List.find(id)
      |> Mrgr.HighImpactFileRule.toggle_notification(String.to_existing_atom(attr))

    send(self(), {:hif_updated, hif})

    socket
    |> noreply()
  end
end
