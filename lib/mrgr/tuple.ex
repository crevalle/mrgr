defmodule Mrgr.Tuple do
  def ok(state) do
    {:ok, state}
  end

  def noreply(state) do
    {:noreply, state}
  end

  def cont(state) do
    {:cont, state}
  end

  def halt(state) do
    {:halt, state}
  end

  def take_tag({tag, _value}), do: tag
  def take_value({_tag, value}), do: value
end
