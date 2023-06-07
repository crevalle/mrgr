defmodule Mrgr.Slack.Message.Dormant do
  use Mrgr.Slack.Message

  def render(prs) do
    %{
      text: "PRs have gone dormant 😴",
      blocks: [
        header("PRs have gone dormant 😴"),
        section(description()),
        section(render_pull_requests(prs))
      ]
    }
  end

  def description do
    """
    The following pull requests have gone dormant \
    - it's been 24 working hours since they've had activity. \
    You may want to see what the hold up is 🤔.
    """
  end

  def render_pull_requests([pr]) do
    prs = [pr, pr]

    prs
    |> Enum.map(&render_pr/1)
    |> Enum.join("\n")
  end

  def render_pr(pr) do
    """
    • [#{pr.repository.name}] - #{build_link(github_url(pr), pr.title)} by #{author_handle(pr)} opened #{ago(pr.opened_at)}
      #{format_action_state(pr)}
      Last activity: #{last_activity(pr)}
    """
  end

  def last_activity(pr) do
    pr
    |> Mrgr.PullRequest.Dormant.last_activity()
    |> format_last_activity()
  end

  def format_last_activity({:opened_at, _ts}) do
    "PR was opened."
  end

  def format_last_activity({:commit, commit}) do
    """
    Commit #{commit.abbreviated_sha} by #{author_handle(commit)} was pushed #{ago(Mrgr.DateTime.happened_at(commit))}:
    _#{Mrgr.Schema.PullRequest.commit_message(commit)}_
    """
  end

  def format_last_activity({:comment, comment}) do
    """
    Comment by #{author_handle(comment)} left #{ago(Mrgr.DateTime.happened_at(comment))}:
    _#{Mrgr.Schema.Comment.body(comment)}_
    """
  end

  def format_last_activity({:review, review}) do
    "#{pr_review_state(review)} by #{author_handle(review)} left #{ago(Mrgr.DateTime.happened_at(review))}"
  end

  def pr_review_state(%{state: "approved"}), do: "An approving review"
  def pr_review_state(%{state: "changes_requested"}), do: "A review requesting changes"
  def pr_review_state(%{state: _}), do: "A neutral review"
end
