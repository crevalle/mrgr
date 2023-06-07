defmodule Mrgr.Notification.Dormant do
  use Mrgr.Notification.Event

  @spec notify_consumers(Mrgr.Schema.PullRequest.t()) :: Mrgr.Notification.result()
  def notify_consumers(pull_request) do
    consumers = fetch_consumers(pull_request)

    Enum.reduce(consumers, %{}, fn {channel, recipients}, acc ->
      results = notify_channel(channel, recipients, pull_request)

      Map.put(acc, channel, results)
    end)
  end

  def notify_channel(:email, recipients, pull_request) do
    Enum.map(recipients, fn recipient ->
      send_email(recipient, pull_request)
    end)
  end

  def notify_channel(:slack, recipients, pull_request) do
    Enum.map(recipients, fn recipient ->
      send_slack_message(recipient, pull_request)
    end)
  end

  def send_email(_recipient, _pull_request) do
    # email = Mrgr.Email.dormant_pr(recipient, pull_request)

    # Mrgr.Mailer.deliver_and_log(email, @dormant_pr)
  end

  def send_slack_message(_recipient, _pull_request) do
    # message = Mrgr.Slack.Message.DormantPR.render(pull_request, recipient)

    # Mrgr.Slack.send_and_log(message, recipient, @dormant_pr)
  end

  def fetch_consumers(pull_request) do
    Mrgr.Notification.consumers_of_event(@dormant_pr, pull_request)
  end
end
