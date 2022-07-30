defmodule Mrgr.FileChangeAlertTest do
  use ExUnit.Case

  describe "pattern_matches_filenames?/2" do
    test "matches file names" do
      assert Mrgr.FileChangeAlert.pattern_matches_filenames?("foo.ex", ["foo.ex"])
      refute Mrgr.FileChangeAlert.pattern_matches_filenames?("foo.ex", ["bar.ex"])

      assert Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/foo.ex", ["lib/foo.ex"])
      refute Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/foo.ex", ["foo.ex"])
    end

    test "matches directories" do
      refute Mrgr.FileChangeAlert.pattern_matches_filenames?("lib", ["lib/foo.ex"])
      refute Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/", ["lib/foo.ex"])
      assert Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/*", ["lib/foo.ex"])
      assert Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/**/foo.ex", ["lib/bar/foo.ex"])

      assert Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/foo.ex", ["lib/foo.ex"])
      refute Mrgr.FileChangeAlert.pattern_matches_filenames?("lib/foo.ex", ["foo.ex"])
    end
  end
end
