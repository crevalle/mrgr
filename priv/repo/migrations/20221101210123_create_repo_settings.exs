defmodule Mrgr.Repo.Migrations.CreateRepoSettings do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add(:settings, :map, default: "{}")
    end

    create table(:repository_security_profiles) do
      add(:apply_to_new_repos, :boolean)
      add(:installation_id, references(:installations))
      add(:settings, :map, default: "{}")

      timestamps()
    end

    create index(:repository_security_profiles, :installation_id)
  end
end
