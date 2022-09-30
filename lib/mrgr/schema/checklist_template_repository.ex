defmodule Mrgr.Schema.ChecklistTemplateRepository do
  use Mrgr.Schema

  schema "checklist_template_repositories" do
    belongs_to(:checklist_template, Mrgr.Schema.ChecklistTemplate)
    belongs_to(:repository, Mrgr.Schema.Repository)

    timestamps()
  end
end
