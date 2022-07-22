defmodule Mrgr.Schema.IncomingWebhook do
  use Mrgr.Schema

  schema "incoming_webhooks" do
    field(:source, :string)
    field(:object, :string)
    field(:action, :string)
    field(:data, :map)
    field(:headers, :map)

    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:source, :object, :action, :data, :installation_id, :headers])
    |> foreign_key_constraint(:installation_id)
  end
end
