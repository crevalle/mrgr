defmodule Mrgr.Query do
  @moduledoc """
  Common query helpers
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      @spec by_id(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
      def by_id(queryable, id) do
        from(q in queryable,
          where: q.id == ^id
        )
      end

      def by_external_id(queryable, id) do
        from(q in queryable,
          where: q.external_id == ^id
        )
      end
    end
  end
end
