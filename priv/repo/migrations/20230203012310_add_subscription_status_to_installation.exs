defmodule Mrgr.Repo.Migrations.AddSubscriptionStatusToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:subscription_state, :string)
      add(:subscription_state_changes, :map, default: "[]")
    end
  end
end
