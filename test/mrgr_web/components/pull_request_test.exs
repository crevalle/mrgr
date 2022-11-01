defmodule MrgrWeb.Components.PullRequestTest do
  use ExUnit.Case

  describe "filter_recent_comments/1" do
    test "keeps comments created in the last 24 hours" do
      just_now = DateTime.add(DateTime.utc_now(), -5, :minute)
      a_few_hours_ago = DateTime.add(DateTime.utc_now(), -5, :hour)
      over_1_day_ago = DateTime.add(DateTime.utc_now(), -1441, :minute)

      c1 = %Mrgr.Schema.Comment{id: 1, posted_at: just_now}
      c2 = %Mrgr.Schema.Comment{id: 2, posted_at: a_few_hours_ago}
      c3 = %Mrgr.Schema.Comment{id: 3, posted_at: over_1_day_ago}

      res = MrgrWeb.Components.PullRequest.filter_recent_comments([c1, c2, c3])

      assert Enum.map(res, & &1.id) == [1, 2]
    end
  end
end
