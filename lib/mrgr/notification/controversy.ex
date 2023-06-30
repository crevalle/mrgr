defmodule Mrgr.Notification.Controversy do
  use Mrgr.Notification.Event

  def notify_consumers(pull_request, thread) do
    pull_request = Mrgr.Repo.preload(pull_request, :author)
    consumers = fetch_consumers(pull_request)

    email =
      Enum.map(consumers.email, fn recipient ->
        send_controversy_email(recipient, pull_request, thread)
      end)

    slack =
      Enum.map(consumers.slack, fn recipient ->
        send_controversy_slack(recipient, pull_request, thread)
      end)

    %{email: email, slack: slack}
  end

  def fetch_consumers(pull_request) do
    Mrgr.Notification.consumers_of_event(@pr_controversy, pull_request)
  end

  def send_controversy_email(recipient, pull_request, thread) do
    email = Mrgr.Email.controversial_pr(recipient, pull_request, thread)

    Mrgr.Mailer.deliver_and_log(email, @pr_controversy, pull_request)
  end

  def send_controversy_slack(recipient, pull_request, thread) do
    message = Mrgr.Slack.Message.ControversialPR.render(pull_request, thread, recipient)

    Mrgr.Slack.send_and_log(message, recipient, @pr_controversy, pull_request)
  end
end
