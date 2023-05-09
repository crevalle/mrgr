defmodule Mrgr.PullRequest.Controversy do
  import Mrgr.Notification.Event

  @thread_threshold 4

  # already controversial, can't get any worse!
  def handle(%{controversial: true} = pull_request), do: pull_request

  def handle(pull_request) do
    case controversy_brewing?(pull_request) do
      {true, thread} ->
        pull_request
        |> set_controversy_flag()
        |> notify_consumers(thread)

      false ->
        pull_request
    end
  end

  def mark!(pull_request) do
    case controversy_brewing?(pull_request) do
      {true, _thread} ->
        pull_request
        |> set_controversy_flag()

      false ->
        pull_request
    end
  end

  def controversy_brewing?(%{comments: comments}) do
    threads = build_conversation_threads(comments)

    case Enum.find(threads, &longer_than_they_should_be?/1) do
      nil ->
        false

      thread ->
        {true, thread}
    end
  end

  def build_conversation_threads(comments) do
    review_comments = Enum.filter(comments, &(&1.object == :pull_request_review_comment))
    {heads, responses} = Enum.split_with(review_comments, &Mrgr.Schema.Comment.initial_comment?/1)

    {conversations, _} =
      Enum.reduce(heads, {[], responses}, fn head, {threads, responses} ->
        {thread, remaining} = build_thread([head], responses)

        {[thread | threads], remaining}
      end)

    Enum.map(conversations, &Mrgr.Schema.Comment.cron/1)
  end

  defp build_thread([last | _rest_of_thread] = thread, responses) do
    {child, remaining_responses} =
      Enum.split_with(responses, fn r ->
        Mrgr.Schema.Comment.is_a_reply_to?(r, last)
      end)

    put_child(child, thread, remaining_responses)
  end

  defp put_child([], thread, responses), do: {thread, responses}

  defp put_child([child], thread, responses) do
    build_thread([child | thread], responses)
  end

  defp put_child(children, thread, responses) do
    build_thread(children ++ thread, responses)
  end

  defp longer_than_they_should_be?(thread) do
    Enum.count(thread) > @thread_threshold
  end

  def set_controversy_flag(pull_request) do
    pull_request
    |> Ecto.Changeset.change(%{controversial: true})
    |> Mrgr.Repo.update!()
  end

  def notify_consumers(pull_request, thread) do
    pull_request = Mrgr.Repo.preload(pull_request, :author)
    consumers = fetch_consumers(pull_request)

    email = Enum.map(consumers.email, fn recipient ->
      send_controversy_email(recipient, pull_request, thread)
    end)

    slack = Enum.map(consumers.slack, fn recipient ->
      send_controversy_slack(recipient, pull_request, thread)
    end)

    %{email: email, slack: slack}
  end

  def fetch_consumers(pull_request) do
    Mrgr.Notification.consumers_of_event(pr_controversy(), pull_request)
  end

  def send_controversy_email(recipient, pull_request, thread) do
    email = Mrgr.Email.controversial_pr(recipient, pull_request, thread)

    Mrgr.Mailer.deliver(email)
  end

  def send_controversy_slack(recipient, pull_request, thread) do
    message = Mrgr.Slack.Message.ControversialPR.render(pull_request, thread, recipient)

    Mrgr.Slack.send_message(message, recipient)
  end
end
