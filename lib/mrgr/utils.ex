defmodule Mrgr.Utils do
  @moduledoc """
  Common functionality
  """

  def find_item_in_list(list, %{id: id}) do
    find_item_in_list(list, id)
  end

  def find_item_in_list(list, id) when is_bitstring(id) do
    find_item_in_list(list, String.to_integer(id))
  end

  def find_item_in_list(list, id) do
    Enum.find(list, fn i -> i.id == id end)
  end

  def find_item_index_in_list(list, %{id: id}) do
    Enum.find_index(list, fn i -> i.id == id end)
  end

  def replace_item_in_list(list, item) do
    # assumes item is in list

    idx = find_item_index_in_list(list, item)
    List.replace_at(list, idx, item)
  end
end