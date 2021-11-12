defmodule Mrgr.TupleHelpers do
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
end
