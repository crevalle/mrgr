defmodule Mrgr.Repo.Migrations.AddSetupStatusToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:setup_completed, :boolean, default: false)
    end
  end
end
