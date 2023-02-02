defmodule Mrgr.Repo.Migrations.AddStateChangesToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:state_changes, :map, default: "[]")
    end
  end
end
