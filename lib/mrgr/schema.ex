defmodule Mrgr.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}

      # expects string params!
      def put_external_id(changeset) do
        put_change(changeset, :external_id, changeset.params["id"])
      end

      def put_data_map(changeset) do
        put_change(changeset, :data, changeset.params)
      end
    end
  end

  def ts do
    DateTime.truncate(DateTime.utc_now(), :second)
  end
end
