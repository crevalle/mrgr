defmodule Mrgr.PullRequest.Controversy do
  @thread_threshold 4

  # already controversial, can't get any worse!
  def handle(%{controversial: true} = pull_request), do: pull_request

  def handle(pull_request) do
    case controversy_brewing?(pull_request) do
      true ->
        mark_controversial(pull_request)

      false ->
        pull_request
    end
  end

  def controversy_brewing?(%{comments: comments} = pull_request) do
    comments
    |> build_conversation_threads()
    |> Enum.any?(&longer_than_they_should_be?/1)
  end

  def build_conversation_threads(comments) do
    review_comments = Enum.filter(comments, &(&1.object == :pull_request_review_comment))
    {heads, responses} = Enum.split_with(review_comments, &Mrgr.Schema.Comment.initial_comment?/1)

    {conversations, _} =
      Enum.reduce(heads, {[], responses}, fn head, {threads, responses} ->
        {thread, remaining} = build_thread([head], responses)

        {[thread | threads], remaining}
      end)

    conversations
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

  defp longer_than_they_should_be?(thread) do
    Enum.count(thread) > @thread_threshold
  end

  def mark_controversial(pull_request) do
    pull_request
    |> set_controversy_flag()
    |> notify_consumers()
  end

  def set_controversy_flag(pull_request) do
    pull_request
    |> Ecto.Changeset.change(%{controversial: true})
    |> Mrgr.Repo.update!()
  end

  def notify_consumers(pull_request) do
    # TODO
    pull_request
  end
end
