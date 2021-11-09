defmodule Mrgr.Repo.Migrations.CreateWebhookLog do
  use Ecto.Migration

  def change do
    create table(:incoming_webhooks) do
      add(:source, :text)
      add(:object, :text)
      add(:action, :text)
      add(:data, :map)

      timestamps()
    end

  end
end
