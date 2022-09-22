defmodule Mrgr.Repo.Migrations.CreateChecklistTemplate do
  use Ecto.Migration

  def change do
    create table(:checklist_templates) do
      add(:installation_id, references(:installations, on_delete: :delete_all), null: false)
      add(:title, :text, null: false)
      add(:creator_id, references(:users), null: false)

      add(:check_templates, :map, default: "[]")

      timestamps()
    end

    create index(:checklist_templates, :installation_id)
  end
end
