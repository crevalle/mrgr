defmodule Mrgr.Schema.IncomingWebhook do
  use Mrgr.Schema

  schema "incoming_webhooks" do
    field(:source, :string)
    field(:object, :string)
    field(:action, :string)
    field(:data, :map)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:source, :object, :action, :data])
  end
end
