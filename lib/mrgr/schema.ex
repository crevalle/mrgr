defmodule Mrgr.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}

      # this is the most obnoxious thing
      @timestamps_opts [type: :utc_datetime]

      # expects string params!
      def put_external_id(changeset) do
        put_change(changeset, :external_id, changeset.params["id"])
      end

      def put_data_map(changeset) do
        put_change(changeset, :data, changeset.params)
      end

      def put_timestamp(changeset, attr, value \\ Mrgr.DateTime.now()) do
        # cast/3 automatically removes microseconds.  need to explicity
        # do this when calling put_change/3
        # https://elixirforum.com/t/upgrading-to-ecto-3-anyway-to-easily-deal-with-usec-it-complains-with-or-without-usec/22137/7?u=desmond
        sans_ms = Mrgr.DateTime.safe_truncate(value)
        put_change(changeset, attr, sans_ms)
      end
    end
  end
end
