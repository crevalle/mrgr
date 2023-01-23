defmodule Mrgr.Schema.StripeWebhook do
  use Mrgr.Schema

  schema "stripe_webhooks" do
    field(:data, :map)
    field(:external_id, :string)
    field(:type, :string)
    field(:created, :integer)

    timestamps()
  end

  @attrs [:created, :external_id, :type, :data]

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @attrs)
  end
end
