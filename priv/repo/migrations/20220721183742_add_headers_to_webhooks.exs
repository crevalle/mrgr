defmodule Mrgr.Repo.Migrations.AddHeadersToWebhooks do
  use Ecto.Migration

  def change do
    alter table(:incoming_webhooks) do
      add(:headers, :map, default: "{}")
    end
  end
end
