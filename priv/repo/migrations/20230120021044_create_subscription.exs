defmodule Mrgr.Repo.Migrations.CreateSubscription do
  use Ecto.Migration

  def change do
    create table("stripe_subscriptions") do
      add(:node_id, :string)
      add(:webhook_id, references(:stripe_webhooks))
      add(:installation_id, references(:installations, on_delete: :delete_all))

      timestamps()
    end

    create index(:stripe_subscriptions, :installation_id, unique: true)
  end
end
