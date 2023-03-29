defmodule Mrgr.PullRequest.Dormant do
  def dormant?(%Mrgr.Schema.PullRequest{} = pr) do
    pr
    |> most_recent_activity_timestamp()
    |> dormant?()
  end

  def dormant?(timestamp) do
    !fresh?(timestamp) && !stale?(timestamp)
  end

  def most_recent_activity_timestamp(pr) do
    [
      pr.opened_at,
      Mrgr.Schema.PullRequest.latest_comment_date(pr),
      Mrgr.Schema.PullRequest.latest_commit_date(pr),
      Mrgr.Schema.PullRequest.latest_pr_review_date(pr)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1, {:desc, DateTime})
    |> hd()
  end

  def fresh?(timestamp) do
    Mrgr.DateTime.before?(fresh_threshold(), timestamp)
  end

  def stale?(timestamp) do
    Mrgr.DateTime.before?(timestamp, stale_threshold())
  end

  def fresh_threshold do
    now = Mrgr.DateTime.now()
    offset = fresh_offset(Date.day_of_week(now))

    set_offset(now, offset)
  end

  def stale_threshold do
    now = Mrgr.DateTime.now()
    offset = stale_offset(Date.day_of_week(now))

    set_offset(now, offset)
  end

  defp set_offset(now, offset) do
    now
    |> DateTime.add(-offset, :hour)
    |> Mrgr.DateTime.safe_truncate()
  end

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
