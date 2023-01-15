defmodule Mrgr.Notifier do
  # weird dependency going to -> MrgrWeb, but oh well
  # bigger fish to fry
  use Phoenix.Swoosh, view: MrgrWeb.NotifierView

  def hif_alert(recipient, repository, hif_alerts, url) do
    assigns = %{
      hif_alerts: hif_alerts,
      repository_name: repository.name,
      url: url
    }

    new()
    |> from("noreply@mrgr.io")
    |> to(recipient.email)
    |> subject("[Mrgr] File Change Alert in #{assigns.repository_name}")
    |> render_body("hif_alert.html", assigns)
  end
end
