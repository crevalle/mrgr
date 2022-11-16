defmodule Mrgr.Repo.Migrations.AddReposLastSyncedAtToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:repos_last_synced_at, :utc_datetime)
    end
  end
end
