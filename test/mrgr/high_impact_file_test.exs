defmodule Mrgr.HighImpactFileTest do
  use ExUnit.Case

  describe "pattern_matches_filename?/2" do
    test "matches file name" do
      assert Mrgr.HighImpactFile.pattern_matches_filename?("foo.ex", "foo.ex")
      refute Mrgr.HighImpactFile.pattern_matches_filename?("bar.ex", "foo.ex")

      assert Mrgr.HighImpactFile.pattern_matches_filename?("lib/foo.ex", "lib/foo.ex")
      refute Mrgr.HighImpactFile.pattern_matches_filename?("foo.ex", "lib/foo.ex")
    end

    test "matches directories" do
      refute Mrgr.HighImpactFile.pattern_matches_filename?("lib/foo.ex", "lib")
      refute Mrgr.HighImpactFile.pattern_matches_filename?("lib/foo.ex", "lib/")
      assert Mrgr.HighImpactFile.pattern_matches_filename?("lib/foo.ex", "lib/*")
      assert Mrgr.HighImpactFile.pattern_matches_filename?("lib/bar/foo.ex", "lib/**/foo.ex")
    end
  end
end
