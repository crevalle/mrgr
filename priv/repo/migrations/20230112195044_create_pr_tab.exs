defmodule Mrgr.Repo.Migrations.CreatePRTab do
  use Ecto.Migration

  def change do
    create table(:pr_tabs) do
      add(:title, :string)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create index(:pr_tabs, :user_id)
  end
end
