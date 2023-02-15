defmodule Mrgr.Notifier do
  # weird dependency going to -> MrgrWeb, but oh well
  # bigger fish to fry
  use Phoenix.Swoosh, view: MrgrWeb.NotifierView
  use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router

  def hif_alert(alerts, recipient, pull_request_id, repository) do
    url = ~p"/pull-requests/hifs/#{pull_request_id}/files-changed"

    assigns = %{
      hif_alerts: alerts,
      repository_name: repository.name,
      url: url
    }

    new()
    |> from("noreply@mrgr.io")
    |> to(recipient.notification_email)
    |> subject("[Mrgr] File Change Alert in #{assigns.repository_name}")
    |> render_body("hif_alert.html", assigns)
  end
end
