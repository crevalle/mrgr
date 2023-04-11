defmodule Mrgr.ControversyTest do
  use Mrgr.DataCase

  describe "build_conversation_threads/1" do
    issue_comment = build(:comment, object: :issue_comment)
    thread_1 = build(:pull_request_review_comment, raw: %{"id" => 1}, pull_request: nil)
    thread_2 = build(:pull_request_review_comment, raw: %{"id" => 2}, pull_request: nil)
    thread_3 = build(:pull_request_review_comment, raw: %{"id" => 3}, pull_request: nil)

    response_1_1 =
      build(:pull_request_review_comment,
        raw: %{"id" => 4, "in_reply_to_id" => 1},
        pull_request: nil
      )

    response_1_2 =
      build(:pull_request_review_comment,
        raw: %{"id" => 5, "in_reply_to_id" => 4},
        pull_request: nil
      )

    response_2_1 =
      build(:pull_request_review_comment,
        raw: %{"id" => 6, "in_reply_to_id" => 2},
        pull_request: nil
      )

    comments = [
      issue_comment,
      thread_1,
      thread_2,
      thread_3,
      response_1_1,
      response_1_2,
      response_2_1
    ]

    result = Mrgr.PullRequest.Controversy.build_conversation_threads(comments)

    assert Enum.count(result) == 3
    [first, second, third] = result

    # built backwards, since we prepend the results in the reduce
    assert Enum.count(first) == 1
    assert Enum.count(second) == 2
    assert Enum.count(third) == 3
  end
end
