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
    Mrgr.DateTime.now()
    |> DateTime.add(-24, :hour)
    |> Mrgr.DateTime.safe_truncate()
  end

  def stale_threshold do
    Mrgr.DateTime.now()
    |> DateTime.add(-72, :hour)
    |> Mrgr.DateTime.safe_truncate()
  end
end
