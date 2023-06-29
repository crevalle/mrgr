defmodule Mrgr.Slack.Message.BigPR do
  use Mrgr.Slack.Message

  def render(pull_request) do
    %{
      text: "Big PR opened in #{repo_name(pull_request)} 🗂️",
      blocks: [
        header("Big PR opened 🗂️"),
        section(body(pull_request)),
        section(details(pull_request)),
        actions(button("View it on Github", github_url(pull_request)))
      ]
    }
  end

  def body(pull_request) do
    "#{author_handle(pull_request)} opened the very big PR #{build_link(github_url(pull_request), pull_request.title)} in the *#{repo_name(pull_request)}* repository."
  end

  def details(pull_request) do
    """
    Additions: #{number_with_delimiter(pull_request.additions)} 🟢
    Deletions: #{number_with_delimiter(pull_request.deletions)} 🔴
    """
  end
end
