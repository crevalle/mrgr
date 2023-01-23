defmodule Mrgr.Repo.Migrations.CreateStripeWebhooks do
  use Ecto.Migration

  def change do
    create table(:stripe_webhooks) do
      add(:external_id, :string)
      add(:type, :string)
      add(:data, :map)
      add(:created, :integer)

      timestamps()
    end
  end
end
