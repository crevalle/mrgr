defmodule Mrgr.Repo.Migrations.CreateMemberPRTab do
  use Ecto.Migration

  def change do
    create table(:member_pr_tabs) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :member_id, references(:members, on_delete: :delete_all)

      timestamps()
    end

    create index(:member_pr_tabs, [:user_id, :member_id], unique: true)
  end
end
