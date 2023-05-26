defmodule Mrgr.Notification.Dormant do
  use Mrgr.Notification.Event

  def notify_user_of_dormant_prs(_installation_id, []), do: nil

  def notify_user_of_dormant_prs(installation_id, prs) do
    consumers = Mrgr.Notification.consumers_of_event(@dormant_pr, installation_id)

    # Enum.map(consumers.email, fn recipient -> send_email(recipient, prs) end)

    Enum.map(consumers.slack, fn recipient -> send_slack(recipient, prs) end)
  end

  # def send_email(recipient, prs) do
  # email = Mrgr.Email.dormant_prs(recipient, prs)

  # Mrgr.Mailer.deliver(email)
  # end

  def send_slack(recipient, prs) do
    message = Mrgr.Slack.Message.Dormant.render(prs)

    Mrgr.Slack.send_message(message, recipient)
  end
end
