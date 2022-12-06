defmodule Mrgr.Repo.Migrations.CreatePRTabLabels do
  use Ecto.Migration

  def change do
    create table(:label_pr_tabs) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:label_id, references(:labels, on_delete: :delete_all))
      add(:position, :integer, null: false)

      timestamps()
    end

    create index(:label_pr_tabs, :user_id)
  end
end
