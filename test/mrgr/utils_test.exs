defmodule Mrgr.UtilsTest do
  use ExUnit.Case

  describe "remove_item_from_list/2" do
    test "excises an element from a list if ids match" do
      list = [%{id: 3}]
      res = Mrgr.Utils.remove_item_from_list(list, 3)

      assert res == []
    end

    test "handles string ids" do
      list = [%{id: 3}]
      res = Mrgr.Utils.remove_item_from_list(list, "3")

      assert res == []
    end
  end
end
