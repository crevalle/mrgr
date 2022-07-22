defmodule Mrgr.Repo.Migrations.AddInstallationIdToWebhooks do
  use Ecto.Migration

  def change do
    alter table(:incoming_webhooks) do
      add(:installation_id, references(:installations))
    end

    create index(:incoming_webhooks, :installation_id)
  end
end
