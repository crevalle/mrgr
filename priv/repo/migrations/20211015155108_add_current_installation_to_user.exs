defmodule Mrgr.Repo.Migrations.AddCurrentInstallationToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:current_installation_id, references(:installations))
    end
  end
end
