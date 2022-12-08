defmodule Mrgr.Github.Schema do
  def to_attrs(struct) when is_struct(struct) do
    attrs = Map.from_struct(struct)
    Map.put(attrs, :external_id, attrs.id)
  end

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}
      # @primary_key {:uuid, :binary_id, []}
      @primary_key false
    end
  end
end
