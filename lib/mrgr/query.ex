defmodule Mrgr.Query do
  @moduledoc """
  Common query helpers
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      @spec by_id(Ecto.Queryable.t(), integer() | String.t()) :: Ecto.Query.t()
      def by_id(queryable, id) when is_integer(id) do
        from(q in queryable,
          where: q.id == ^id
        )
      end

      def by_id(queryable, id) when is_bitstring(id) do
        by_id(queryable, String.to_integer(id))
      end

      def by_external_id(queryable, id) do
        from(q in queryable,
          where: q.external_id == ^id
        )
      end
    end
  end
end
