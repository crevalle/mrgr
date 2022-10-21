defmodule MrgrWeb.SparklineTest do
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

      # yikes, would be nice if the bucket filtered these :/
      bucket =
        comments
        |> MrgrWeb.Components.Live.Sparkline.filter_recent()
        |> MrgrWeb.Components.Live.Sparkline.bucketize()

      assert bucket[0] == 1
      assert bucket[1] == 1
      assert bucket[2] == 0
      assert bucket[3] == 0
      assert bucket[17] == 1
      assert bucket[23] == 0

      assert Enum.sum(Map.values(bucket)) == 3
    end
  end

  describe "bucketize/1" do
    test "combines comments and commits into a bucket of previous 24 hours" do
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

      commits = build_stupid_commits([last_hour, two_hours_ago, seventeen_hours, yesterday])

      stuff = comments ++ commits

      bucket =
        stuff
        |> MrgrWeb.Components.Live.Sparkline.filter_recent()
        |> MrgrWeb.Components.Live.Sparkline.Bucket.new()

      # higher numbers
      assert bucket[0] == 2
      assert bucket[1] == 2
      assert bucket[2] == 0
      assert bucket[3] == 0
      assert bucket[17] == 2
      assert bucket[23] == 0

      assert Enum.sum(Map.values(bucket)) == 6
    end
  end

  defp build_stupid_commits(datetimes) do
    # this nested modeling is incredibly stupid.
    Enum.map(datetimes, fn dt ->
      %Mrgr.Github.Commit{
        commit: %Mrgr.Github.Commit.Commit{
          committer: %Mrgr.Github.Commit.ShortUser{date: dt}
        }
      }
    end)
  end
end
