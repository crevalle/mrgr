defmodule Mrgr.Notification.HIF do
  @name "hif"

  def send_alert(pull_request) do
    case Mrgr.Notification.ensure_freshness(pull_request.notifications, @name) do
      :ok -> send_alert!(pull_request)
      already_sent -> already_sent
    end
  end

  def send_alert!(pull_request) do
    with :ok <- has_rules(pull_request) do
      # each user gets one alert per pull request with all applicable rules
      pull_request =
        pull_request
        |> Mrgr.Repo.preload(:author)

      pull_request.high_impact_file_rules
      # don't send alerts to whomever opened the PR
      |> Enum.reject(&hif_consumer_is_author?(&1, pull_request.author))
      |> Enum.group_by(& &1.user_id)
      |> Enum.map(&do_send_alert(&1, pull_request))
    end
  end

  def has_rules(%{high_impact_file_rules: []}), do: {:error, :no_rules}
  def has_rules(%{high_impact_file_rules: _rules}), do: :ok

  defp do_send_alert({user_id, rules}, pull_request) do
    recipient = Mrgr.User.find_with_current_installation(user_id)

    rules_by_channel =
      rules
      |> Enum.map(fn rule ->
        %{rule | filenames: Mrgr.HighImpactFileRule.matching_filenames(rule, pull_request)}
      end)
      |> Mrgr.Notification.bucketize_preferences()

    email_results = send_email_alert(rules_by_channel.email, recipient, pull_request)
    slack_results = send_slack_alert(rules_by_channel.slack, recipient, pull_request)

    %{email: email_results, slack: slack_results}
  end

  @spec hif_consumer_is_author?(Schema.t(), Mrgr.Schema.PullRequest.t()) :: boolean()
  def hif_consumer_is_author?(%{user_id: user_id}, %{user_id: user_id}), do: true
  def hif_consumer_is_author?(_hif, _pr), do: false

  def send_email_alert([], _recipient, _pull_request), do: nil

  def send_email_alert(rules, recipient, pull_request) do
    email = Mrgr.Email.hif_alert(rules, recipient, pull_request)

    Mrgr.Mailer.deliver_and_log(email, @name, pull_request)
  end

  def send_slack_alert([], _recipient, _pull_request), do: nil

  def send_slack_alert(rules, recipient, pull_request) do
    message = Mrgr.Slack.Message.HIFAlert.render(pull_request, rules)

    Mrgr.Slack.send_and_log(message, recipient, @name, pull_request)
  end
end
