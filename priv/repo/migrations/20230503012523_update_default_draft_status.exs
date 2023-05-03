defmodule Mrgr.Repo.Migrations.UpdateDefaultDraftStatus do
  use Ecto.Migration

  def up do
    alter table(:pr_tabs) do
      modify :draft_status, :string, default: "ready_for_review"
    end

    execute "UPDATE pr_tabs SET draft_status = 'ready_for_review' WHERE draft_status = 'open';"
  end

  def down do
    alter table(:pr_tabs) do
      modify :draft_status, :string, default: "open"
    end

    execute "UPDATE pr_tabs SET draft_status = 'open' WHERE draft_status = 'ready_for_review';"
  end
end
