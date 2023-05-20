defmodule Mrgr.Slack.Message.Dormant do
  use Mrgr.Slack.Message

  def render(prs) do


    %{
      text: "PRs have gone dormant",
      blocks: [
        header("PRs have gone dormant"),
        section(description()),
        section(render_pull_requests(prs)),
        section(footer())
      ]
    }
  end

  def description do
    """
    The following pull requests have gone dormant \
    - it's been 24 working hours since they've had activity.\
    \n\n\
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
    • [#{pr.repository.name}] - #{build_link(github_url(pr), pr.title)} by #{author_handle(pr)}
      Ready to Merge | Opened last Thursday
    """

  end

  def footer do
    "i have ants in my pants"

  end
end
