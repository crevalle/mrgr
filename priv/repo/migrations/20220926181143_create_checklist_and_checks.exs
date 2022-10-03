defmodule Mrgr.Repo.Migrations.CreateChecklistAndChecks do
  use Ecto.Migration

  def change do
    create table(:checklists) do
      add :checklist_template_id, references(:checklist_templates, on_delete: :nilify_all)
      add :merge_id, references(:merges, on_delete: :delete_all), null: false

      add :title, :text

      timestamps
    end

    create index(:checklists, :merge_id)
    create index(:checklists, :checklist_template_id)

    ### ----------------------------------

    create table(:checks) do
      add :checklist_id, references(:checklists, on_delete: :delete_all), null: false
      add :text, :text

      timestamps
    end

    create index(:checks, :checklist_id)

    ### ----------------------------------

    create table(:check_approvals) do
      add :check_id, references(:checks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps
    end

    create index(:check_approvals, [:check_id, :user_id], unique: true)
    create index(:check_approvals, [:user_id, :check_id], unique: true)
  end
end
