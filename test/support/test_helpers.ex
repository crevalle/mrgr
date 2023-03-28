defmodule Mrgr.TestHelpers do
  use ExUnit.Case

  def ids(list) when is_list(list) do
    Enum.map(list, & &1.id)
  end
end
