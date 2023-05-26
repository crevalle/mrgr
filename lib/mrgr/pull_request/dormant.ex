defmodule Mrgr.PullRequest.Dormant do

  # def notify(pull_request, user) do
    # pull_request = mark_dormancy_notified(pull_request)

    # notify_consumers(pull_request)
  # end

  # def notify_consumers(pull_request) do
    # consumers = fetch_consumers(pull_request)

    # email = Enum.map(consumers.email, fn recipient ->
      # send_dormant_email(recipient, pull_request)
    # end)

    # slack = Enum.map(consumers.slack, fn recipient ->
      # send_dormant_slack(recipient, pull_request)
    # end)

    # %{email: email, slack: slack}
  # end

  # def mark_dormancy_notified(pull_request) do
    # pull_request
    # |> Ecto.Changeset.change(%{dormancy_notified: true})
    # |> Mrgr.Repo.update!()
  # end

  # def mark_dormancy_reset(pull_request) do
    # pull_request
    # |> Ecto.Changeset.change(%{dormancy_notified: false})
    # |> Mrgr.Repo.update!()
  # end

  # def send_dormant_email(recipient, pull_request) do
    # email = Mrgr.Email.dormant_pr(recipient, pull_request)

    # Mrgr.Mailer.deliver(email)
  # end

  # def send_dormant_slack(recipient, pull_request) do
    # message = Mrgr.Slack.Message.DormantPR.render(pull_request, recipient)

    # Mrgr.Slack.send_message(message, recipient)
  # end

  # def fetch_consumers(pull_request) do
    # Mrgr.Notification.consumers_of_event(Mrgr.Notification.Event.pr_dormant(), pull_request)
  # end

  def dormant?(%Mrgr.Schema.PullRequest{} = pr, timezone) do
    dormant?(pr.last_activity_at, timezone)
  end

  def dormant?(timestamp, timezone) do
    !fresh?(timestamp, timezone) && !stale?(timestamp, timezone)
  end

  def most_recent_activity_timestamp(pr) do
    pr
    |> recent_timestamps()
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1, {:desc, DateTime})
    |> hd()
  end

  def recent_timestamps(pr) do
    %{
      opened_at: pr.opened_at,
      commented_at: Mrgr.Schema.PullRequest.latest_comment_date(pr),
      committed_at: Mrgr.Schema.PullRequest.latest_commit_date(pr),
      reviewed_at: Mrgr.Schema.PullRequest.latest_pr_review_date(pr)
    }
  end

  def fresh?(timestamp, timezone) do
    localized_timestamp = DateTime.shift_zone!(timestamp, timezone)

    Mrgr.DateTime.before?(fresh_threshold(timezone), localized_timestamp)
  end

  def stale?(timestamp, timezone) do
    localized_timestamp = DateTime.shift_zone!(timestamp, timezone)

    Mrgr.DateTime.before?(localized_timestamp, stale_threshold(timezone))
  end

  def fresh_threshold(timezone) do
    now = DateTime.now!(timezone)
    offset = fresh_offset(Date.day_of_week(now))

    set_offset(now, offset)
  end

  def stale_threshold(timezone) do
    now = DateTime.now!(timezone)
    offset = stale_offset(Date.day_of_week(now))

    set_offset(now, offset)
  end

  defp set_offset(now, offset) do
    now
    |> DateTime.add(-offset, :hour)
    |> Mrgr.DateTime.safe_truncate()
  end

  def window(timezone) do
    # takes local time, returns UTC for db query

    ending =
      timezone
      |> fresh_threshold()
      |> DateTime.shift_zone!("Etc/UTC")

    # assumes job runs every hour.  everything that dormanted in the last hour
    beginning = DateTime.add(ending, -1, :hour)

    %{beginning: beginning, ending: ending}
  end

  # handles weekends, based on current day of week
  def fresh_offset(1), do: 72
  def fresh_offset(2), do: 24
  def fresh_offset(3), do: 24
  def fresh_offset(4), do: 24
  def fresh_offset(5), do: 24
  def fresh_offset(6), do: 48
  def fresh_offset(7), do: 72

  def stale_offset(1), do: 120
  def stale_offset(2), do: 120
  def stale_offset(3), do: 120
  def stale_offset(4), do: 72
  def stale_offset(5), do: 72
  def stale_offset(6), do: 96
  def stale_offset(7), do: 120
end
