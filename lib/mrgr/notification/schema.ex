defmodule Mrgr.Notification.Schema do
  @moduledoc """
  Common functionality of notifiable things, like HIFs, custom pr tabs, and pr events
  """

  defmacro __using__(_opts) do
    quote do
      @channels [:email, :slack]

      def toggle_channel(schema, attr) when is_bitstring(attr) do
        toggle_channel(schema, String.to_existing_atom(attr))
      end

      def toggle_channel(schema, attr) when attr in @channels do
        toggle = !Map.get(schema, attr)

        schema
        |> Ecto.Changeset.change(%{attr => toggle})
        |> Mrgr.Repo.update!()
      end
    end
  end
end
