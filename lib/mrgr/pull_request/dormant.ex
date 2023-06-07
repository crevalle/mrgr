defmodule Mrgr.PullRequest.Dormant do
  # ten years, in days
  @long_time_ago -3650

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

  @spec last_activity(Mrgr.Schema.PullRequest.t()) :: {atom(), struct()}
  def last_activity(pr) do
    pr
    |> latest_activity()
    |> to_sorted_list()
    |> hd()
  end

  def to_sorted_list(activity) do
    activity
    |> Keyword.new()
    |> Enum.sort_by(&activity_haps/1, {:desc, DateTime})
  end

  # guard clause in case there are no comments, commits, etc.
  defp activity_haps({_type, nil}), do: DateTime.add(Mrgr.DateTime.now(), @long_time_ago, :day)
  defp activity_haps({_type, haps}), do: Mrgr.DateTime.happened_at(haps)

  def latest_activity(pr) do
    %{
      opened_at: pr.opened_at,
      comment: Mrgr.Schema.PullRequest.latest_comment(pr),
      commit: Mrgr.Schema.PullRequest.latest_commit(pr),
      review: Mrgr.Schema.PullRequest.latest_pr_review(pr)
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
