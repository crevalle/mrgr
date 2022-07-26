defmodule Mrgr.Repo.Migrations.CreateFileChangeAlerts do
  use Ecto.Migration

  def change do
    create table(:file_change_alerts) do
      add(:pattern, :string)
      add(:badge_text, :string)

      add(:repository_id, references(:repositories))

      timestamps()
    end

    create index(:file_change_alerts, :repository_id)

  end
end
