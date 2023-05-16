defmodule Mrgr.Slack.Message.ControversialPR do
  use Mrgr.Slack.Message

  def render(pull_request, thread, recipient) do
    blocks =
      [
        header("Controversy brewing in #{pull_request.title}"),
        section(description(pull_request)),
        render_thread(thread, recipient),
        actions(button_to_thread(thread))
      ]
      # only flattens the thread
      |> List.flatten()

    %{
      text: "Controversy brewing in #{pull_request.title}",
      blocks: blocks
    }
  end

  def description(pull_request) do
    url = Mrgr.Schema.PullRequest.external_url(pull_request)

    "A comment thread in #{build_link(url, pull_request.title)} by #{author_handle(pull_request)} has generated some controversy and may be worth investigating.  Here's the discussion:"
  end

  def button_to_thread([first | _rest]) do
    button("View thread on Github", Mrgr.Schema.Comment.url(first))
  end

  def render_thread(comments, recipient) do
    Enum.map(comments, fn comment ->
      render_comment(comment, recipient) ++ [divider()]
    end)
  end

  def render_comment(comment, recipient) do
    [
      comment_heading(comment, recipient),
      comment_body(comment)
    ]
  end

  def comment_heading(comment, recipient) do
    %{
      type: "context",
      elements: [
        image(avatar_url(comment), "#{author_handle(comment)}_avatar"),
        text(author_handle(comment)),
        text(ts(comment.posted_at, recipient.timezone))
      ]
    }
  end

  def comment_body(comment) do
    section(Mrgr.Schema.Comment.body(comment))
  end

  def avatar_url(comment) do
    comment
    |> Mrgr.Schema.Comment.author()
    |> Map.get(:avatar_url)
  end
end
