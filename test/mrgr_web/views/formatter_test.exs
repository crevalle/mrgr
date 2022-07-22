defmodule MrgrWeb.Views.FormatterTest do
  use ExUnit.Case

  describe "ago/1" do
    test "when date is less than 1 minute in the past" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -1, :second)) == "<1m"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -59, :second)) == "<1m"
    end

    test "when date is less than 1 hour in the past" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -60, :second)) == "1m"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -59 * 60, :second)) == "59m"
    end

    test "when date is 1 hour or more in the past but less than 1 day" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -60 * 60, :second)) == "1h"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 + 1, :second)) == "23h"
    end

    test "when date is 1 day or more in the past but less than 2 weeks" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400, :second)) == "1d"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * 14 + 1, :second)) == "13d"
    end

    test "when date is 2 weeks or more in the past but less than 8 weeks" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * 14, :second)) == "2w"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * 7 * 8 + 1, :second)) == "7w"
    end

    test "when date is 2 months or more in the past but less than 2 years" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * 7 * 8, :second)) == "2mo"

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * (30 * 18), :second)) ==
               "18mo"

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * (30 * 24) + 1, :second)) ==
               "23mo"
    end

    test "when date is 2 years or more in the past" do
      now = DateTime.utc_now()

      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * (365 * 2), :second)) == "2y"
      assert MrgrWeb.Formatter.ago(DateTime.add(now, -86400 * (365 * 5), :second)) == "5y"
    end
  end
end
