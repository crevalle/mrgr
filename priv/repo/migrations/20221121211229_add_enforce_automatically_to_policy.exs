defmodule Mrgr.Repo.Migrations.AddEnforceAutomaticallyToPolicy do
  use Ecto.Migration

  def change do
    alter table(:repository_settings_policies) do
      add(:enforce_automatically, :boolean, default: true)
    end
  end
end
