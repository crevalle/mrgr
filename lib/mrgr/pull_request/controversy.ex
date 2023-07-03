defmodule Mrgr.PullRequest.Controversy do
  use Mrgr.Notification.Event
  import Mrgr.Tuple

  # already controversial, can't get any worse!
  # nb- we key off this during onboarding, make sure we handle that case
  # if/when we switch to the current "has this notification been sent" logic
  def send_alert(%{controversial: true}), do: {:error, :already_notified}

  def send_alert(pull_request) do
    case controversy_brewing?(pull_request) do
      {true, thread} ->
        pull_request
        |> set_controversy_flag()
        |> Mrgr.Notification.Controversy.notify_consumers(thread)
        |> ok()

      false ->
        {:error, :non_controversial}
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

  def controversy_brewing?(%{comments: comments} = pull_request) do
    %{settings: %{thread_length_threshold: threshold}} =
      Mrgr.Notification.load_creator_preference(pull_request, @pr_controversy)

    threads = build_conversation_threads(comments)

    case Enum.find(threads, fn thread -> longer_than_they_should_be?(thread, threshold) end) do
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

  defp longer_than_they_should_be?(thread, threshold) do
    Enum.count(thread) > threshold
  end

  def set_controversy_flag(pull_request) do
    pull_request
    |> Ecto.Changeset.change(%{controversial: true})
    |> Mrgr.Repo.update!()
  end
end
