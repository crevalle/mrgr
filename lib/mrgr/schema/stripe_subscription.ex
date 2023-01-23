defmodule Mrgr.Schema.StripeSubscription do
  use Mrgr.Schema

  schema "stripe_subscriptions" do
    field(:node_id, :string)

    belongs_to(:webhook, Mrgr.Schema.StripeWebhook)
    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  @attrs [:node_id, :webhook_id, :installation_id]

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @attrs)
  end
end
