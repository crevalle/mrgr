defmodule Mrgr.Assertions do
  use ExUnit.Case

  def assert_list_of_structs_equal(l1, l2) do
    first = Enum.map(l1, & &1.id)

    second = Enum.map(l2, & &1.id)

    assert ^first = second
  end
end
