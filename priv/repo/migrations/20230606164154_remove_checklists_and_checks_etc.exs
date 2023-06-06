defmodule Mrgr.Repo.Migrations.RemoveChecklistsAndChecksEtc do
  use Ecto.Migration

  def up do
    drop table(:check_approvals)
    drop table(:checks)

    drop table(:checklists)
    drop table(:checklist_template_repositories)
    drop table(:checklist_templates)
  end

  def down do
    # irreversible
  end
end
