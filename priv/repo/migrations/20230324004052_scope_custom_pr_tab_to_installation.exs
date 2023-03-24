defmodule Mrgr.Repo.Migrations.ScopeCustomPRTabToInstallation do
  use Ecto.Migration

  def change do
    alter table(:pr_tabs) do
      add(:installation_id, references(:installations, on_delete: :delete_all))
    end
  end
end
