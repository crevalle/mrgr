defmodule Mrgr.FileChangeAlertTest do
  use ExUnit.Case

  describe "pattern_matches_filename?/2" do
    test "matches file name" do
      assert Mrgr.FileChangeAlert.pattern_matches_filename?("foo.ex", "foo.ex")
      refute Mrgr.FileChangeAlert.pattern_matches_filename?("bar.ex", "foo.ex")

      assert Mrgr.FileChangeAlert.pattern_matches_filename?("lib/foo.ex", "lib/foo.ex")
      refute Mrgr.FileChangeAlert.pattern_matches_filename?("foo.ex", "lib/foo.ex")
    end

    test "matches directories" do
      refute Mrgr.FileChangeAlert.pattern_matches_filename?("lib/foo.ex", "lib")
      refute Mrgr.FileChangeAlert.pattern_matches_filename?("lib/foo.ex", "lib/")
      assert Mrgr.FileChangeAlert.pattern_matches_filename?("lib/foo.ex", "lib/*")
      assert Mrgr.FileChangeAlert.pattern_matches_filename?("lib/bar/foo.ex", "lib/**/foo.ex")
    end
  end
end
