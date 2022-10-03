defmodule Mrgr.Repo.Migrations.CreateChecklistTemplateRepoAssociation do
  use Ecto.Migration

  def change do
    create table(:checklist_template_repositories) do
      add :checklist_template_id, references(:checklist_templates, on_delete: :delete_all),
        null: false

      add :repository_id, references(:repositories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:checklist_template_repositories, [:checklist_template_id, :repository_id],
             unique: true
           )

    create index(:checklist_template_repositories, [:repository_id, :checklist_template_id],
             unique: true
           )
  end
end
