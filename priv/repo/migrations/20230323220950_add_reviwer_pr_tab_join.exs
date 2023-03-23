defmodule Mrgr.Repo.Migrations.AddReviwerPRTabJoin do
  use Ecto.Migration

  def change do
    create table(:reviewer_pr_tabs) do
      add(:reviewer_id, references(:members, on_delete: :delete_all), null: false)
      add(:pr_tab_id, references(:pr_tabs, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:reviewer_pr_tabs, [:reviewer_id, :pr_tab_id])
    create index(:reviewer_pr_tabs, [:pr_tab_id, :reviewer_id])
  end
end
