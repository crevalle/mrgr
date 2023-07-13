defmodule Mrgr.List do
  @moduledoc """
  List Utils
  """

  @spec find([map()], map() | String.t() | integer()) :: any() | nil
  def find(list, %{id: id}) do
    find(list, id)
  end

  def find(list, id) when is_bitstring(id) do
    find(list, String.to_integer(id))
  end

  def find(list, id) do
    Enum.find(list, fn i -> i.id == id end)
  end

  # n^n alert!
  def intersection?(l1, l2) when is_list(l1) and is_list(l2) do
    Enum.any?(l1, fn item -> Enum.member?(l2, item) end)
  end

  @spec remove(list(), map() | String.t() | integer()) :: list()
  def remove(list, %{id: id}) do
    remove(list, id)
  end

  def remove(list, id) when is_bitstring(id) do
    remove(list, String.to_integer(id))
  end

  def remove(list, id) do
    Enum.reject(list, fn i -> i.id == id end)
  end

  def add(list, item) do
    [item | list]
  end

  @spec find_index(list(), map()) :: list()
  def find_index(list, %{id: id}) when is_list(list) do
    Enum.find_index(list, fn i -> i.id == id end)
  end

  def replace(list, item) do
    # no-op if not in list

    idx = find_index(list, item)

    case idx do
      nil ->
        list

      idx ->
        List.replace_at(list, idx, item)
    end
  end

  @spec replace!(list(), map()) :: list()
  def replace!(list, item) do
    # if present, replace, else add it

    idx = find_index(list, item)

    case idx do
      nil ->
        add(list, item)

      idx ->
        List.replace_at(list, idx, item)
    end
  end

  @spec present?(list(), map()) :: boolean()
  def present?(list, item) do
    case find(list, item) do
      nil -> false
      _i -> true
    end
  end

  @spec absent?(list(), map()) :: boolean()
  def absent?(list, item), do: !present?(list, item)
end
