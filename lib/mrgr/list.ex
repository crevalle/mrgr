defmodule Mrgr.List do
  @moduledoc """
  List Utils
  """

  def find(list, %{id: id}) do
    find(list, id)
  end

  def find(list, id) when is_bitstring(id) do
    find(list, String.to_integer(id))
  end

  def find(list, id) do
    Enum.find(list, fn i -> i.id == id end)
  end

  def remove(list, id) when is_bitstring(id) do
    remove(list, String.to_integer(id))
  end

  def remove(list, id) do
    Enum.reject(list, fn i -> i.id == id end)
  end

  def find_index(list, %{id: id}) do
    Enum.find_index(list, fn i -> i.id == id end)
  end

  def replace(list, item) do
    # assumes item is in list

    idx = find_index(list, item)
    List.replace_at(list, idx, item)
  end

  def present?(list, item) do
    case find(list, item) do
      nil -> false
      _i -> true
    end
  end

  def absent?(list, item), do: !present?(list, item)
end
