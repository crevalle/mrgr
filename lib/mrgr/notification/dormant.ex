defmodule Mrgr.Notification.Dormant do
  use Mrgr.Notification.Event

  @moduledoc """
  These notifications assume there will be at least one PR in them, that is, that many PRs will go dormant
  'at one time' - within the hour that the dormancy alarm runs - and the user will get a single
  notification for all of the PRs.  This is in contrast to other alerts that are typically 1-1 with
  PRs.

  We can obviously pass in a list of one pr that's gone dormant, if we want.  Just calling out here
  that the main use case will likely involve >1 PRs and users won't want a ton of alerts.

  This alert may be sent multiple times on a single PR, ie, if it keeps going dormant we want
  to know about that each time.  Just don't send it twice during a single dormancy period, plz.
  """

  @spec notify_consumers([Mrgr.Schema.PullRequest.t()], integer()) :: Mrgr.Notification.result()
  def notify_consumers([], _installation_id) do
    %{email: [], slack: []}
  end

  def notify_consumers(pull_requests, installation_id) do
    # make sure this installation id is for these pull requests!
    consumers = fetch_consumers(installation_id)

    Enum.reduce(consumers, %{}, fn {channel, recipients}, acc ->
      results = notify_channel(channel, recipients, pull_requests)

      Map.put(acc, channel, results)
    end)
  end

  def notify_channel(:email, recipients, pull_requests) do
    Enum.map(recipients, fn recipient ->
      send_email(recipient, pull_requests)
    end)
  end

  def notify_channel(:slack, recipients, pull_requests) do
    Enum.map(recipients, fn recipient ->
      send_slack_message(recipient, pull_requests)
    end)
  end

  def send_email(recipient, pull_requests) do
    email = Mrgr.Email.dormant_pr(recipient, pull_requests)

    Mrgr.Mailer.deliver_and_log(email, @dormant_pr, pull_requests)
  end

  def send_slack_message(recipient, pull_requests) do
    message = Mrgr.Slack.Message.Dormant.render(pull_requests)

    Mrgr.Slack.send_and_log(message, recipient, @dormant_pr, pull_requests)
  end

  def fetch_consumers(installation_id) do
    Mrgr.Notification.consumers_of_event(@dormant_pr, installation_id)
  end
end
