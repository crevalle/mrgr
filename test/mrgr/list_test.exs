defmodule Mrgr.ListTest do
  use ExUnit.Case

  describe "remove/2" do
    test "excises an element from a list if ids match" do
      list = [%{id: 3}]
      res = Mrgr.List.remove(list, 3)

      assert res == []
    end

    test "handles string ids" do
      list = [%{id: 3}]
      res = Mrgr.List.remove(list, "3")

      assert res == []
    end
  end
end
