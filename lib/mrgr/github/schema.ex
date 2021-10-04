defmodule Mrgr.Github.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}
      @primary_key false
    end
  end
end
