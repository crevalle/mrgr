defmodule Mrgr.Repo.Migrations.FixCurrentInstallationConstraint do
  use Ecto.Migration

  def change do
    drop constraint("users", "users_current_installation_id_fkey")

    alter table(:users) do
      modify(:current_installation_id, references(:installations, on_delete: :nilify_all))
    end
  end
end
