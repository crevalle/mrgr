defmodule Mrgr.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add(:name, :string, null: false)
      add(:description, :string)
      add(:bg_color, :string, null: false)
      add(:installation_id, references(:installations, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:labels, :installation_id)

    create table(:label_repositories) do
      add(:label_id, references(:labels, on_delete: :delete_all), null: false)
      add(:repository_id, references(:repositories, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:label_repositories, [:label_id, :repository_id], unique: true)
    create index(:label_repositories, [:repository_id, :repository_id], unique: true)
  end
end
