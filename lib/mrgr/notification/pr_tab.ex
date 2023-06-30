defmodule Mrgr.Notification.PRTab do
  def notify_consumers(pull_request) do
    pull_request =
      Mrgr.Repo.preload(pull_request, [:labels, :author, :repository, :solicited_reviewers])

    consumers = fetch_consumers(pull_request)

    email =
      Enum.map(consumers.email, fn tab ->
        send_email(tab.user, pull_request, tab)
      end)

    slack =
      Enum.map(consumers.slack, fn tab ->
        send_slack(tab.user, pull_request, tab)
      end)

    %{email: email, slack: slack}
  end

  def fetch_consumers(pull_request) do
    Mrgr.PRTab.matching_pull_request(pull_request)
    |> Mrgr.Notification.bucketize_preferences()
  end

  # a PR may apply to many tabs.  a user should get only one alert
  # pick the first tab because it matters more that the user gets *an* alert
  # instead of saying "here's all the possible things this matches".
  # It's likely a PR will match only one tab.
  # if tabs have different notification settings then they'll get the alert
  # on whichever channels apply to the first matching tab.  good enough for now.
  def send_email(recipient, pull_request, tab) do
    email = Mrgr.Email.pr_tab(recipient, pull_request, tab)

    Mrgr.Mailer.deliver_and_log(email, name(tab), pull_request)
  end

  def send_slack(recipient, pull_request, tab) do
    message = Mrgr.Slack.Message.PRTab.render(pull_request, tab)

    Mrgr.Slack.send_and_log(message, recipient, name(tab), pull_request)
  end

  def name(tab) do
    Mrgr.Notification.Event.custom_type(tab)
  end
end
