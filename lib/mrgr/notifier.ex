defmodule Mrgr.Notifier do
  # weird dependency going to -> MrgrWeb, but oh well
  # bigger fish to fry
  use Phoenix.Swoosh, view: MrgrWeb.NotifierView

  def file_alert(recipient, repository, file_alerts, url) do
    assigns = %{
      file_alerts: file_alerts,
      repository_name: repository.name,
      url: url
    }

    new()
    |> from("noreply@mrgr.io")
    |> to(recipient.email)
    |> subject("[Mrgr] File Change Alert in #{assigns.repository_name}")
    |> render_body("file_alert.html", assigns)
  end
end
