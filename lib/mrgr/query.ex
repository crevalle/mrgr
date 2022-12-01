defmodule Mrgr.Query do
  @moduledoc """
  Common query helpers
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Query

      def where(query, conditions) do
        from(q in query,
          where: ^conditions
        )
      end

      @spec by_id(Ecto.Queryable.t(), integer() | String.t()) :: Ecto.Query.t()
      def by_id(queryable, id) when is_integer(id) do
        from(q in queryable,
          where: q.id == ^id
        )
      end

      def by_id(queryable, id) when is_bitstring(id) do
        by_id(queryable, String.to_integer(id))
      end

      def by_ids(queryable, list) do
        from(q in queryable,
          where: q.id in ^list
        )
      end

      def by_node_ids(queryable, list) do
        from(q in queryable,
          where: q.node_id in ^list
        )
      end

      def by_external_id(queryable, id) do
        from(q in queryable,
          where: q.external_id == ^id
        )
      end

      def by_node_id(queryable, id) do
        from(q in queryable,
          where: q.node_id == ^id
        )
      end

      def limit(queryable, limit) do
        from(q in queryable,
          limit: ^limit
        )
      end

      def rev_cron(queryable) do
        order(queryable, desc: :inserted_at)
      end

      def cron(queryable) do
        order(queryable, asc: :inserted_at)
      end

      def order(queryable, opts) do
        queryable
        |> order_by(^opts)
      end

      def order_by_insensitive(query, [{direction, field}]) do
        from(q in query,
          order_by: {^direction, fragment("lower(?)", field(q, ^field))}
        )
      end
    end
  end
end
