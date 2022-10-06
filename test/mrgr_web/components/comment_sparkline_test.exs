defmodule MrgrWeb.CommentSparklineTest do
  use ExUnit.Case

  describe "bucketize_comments/1" do
    test "groups comments by how long ago they were created" do
      last_hour = DateTime.add(DateTime.utc_now(), -5, :minute)
      two_hours_ago = DateTime.add(DateTime.utc_now(), -63, :minute)
      seventeen_hours = DateTime.add(DateTime.utc_now(), -17, :hour)
      yesterday = DateTime.add(DateTime.utc_now(), -1441, :minute)

      comments = [
        %Mrgr.Schema.Comment{posted_at: last_hour},
        %Mrgr.Schema.Comment{posted_at: two_hours_ago},
        %Mrgr.Schema.Comment{posted_at: seventeen_hours},
        %Mrgr.Schema.Comment{posted_at: yesterday}
      ]

      bucket = MrgrWeb.Components.Live.CommentSparkline.bucketize(comments)

      assert bucket[0] == 1
      assert bucket[1] == 1
      assert bucket[2] == 0
      assert bucket[3] == 0
      assert bucket[17] == 1
      assert bucket[23] == 0

      assert Enum.sum(Map.values(bucket)) == 3
    end
  end
end
