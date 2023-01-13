defmodule Mrgr.Repo.Migrations.CreatePRTab do
  use Ecto.Migration

  def up do
    drop_if_exists(table(:label_pr_tabs))
    drop_if_exists(table(:member_pr_tabs))

    create table(:pr_tabs) do
      add(:title, :string)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:pr_tabs, :user_id)

    create table(:author_pr_tabs) do
      add(:author_id, references(:members, on_delete: :delete_all), null: false)
      add(:pr_tab_id, references(:pr_tabs, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:author_pr_tabs, [:author_id, :pr_tab_id])
    create index(:author_pr_tabs, [:pr_tab_id, :author_id])

    create table(:label_pr_tabs) do
      add(:label_id, references(:labels, on_delete: :delete_all), null: false)
      add(:pr_tab_id, references(:pr_tabs, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:label_pr_tabs, [:label_id, :pr_tab_id])
    create index(:label_pr_tabs, [:pr_tab_id, :label_id])

    create table(:repository_pr_tabs) do
      add(:repository_id, references(:repositories, on_delete: :delete_all), null: false)
      add(:pr_tab_id, references(:pr_tabs, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:repository_pr_tabs, [:repository_id, :pr_tab_id])
    create index(:repository_pr_tabs, [:pr_tab_id, :repository_id])
  end

  def down do
    ##

    drop_if_exists(table(:label_pr_tabs))
    drop_if_exists(table(:author_pr_tabs))
    drop_if_exists(table(:repository_pr_tabs))
    drop_if_exists(table(:pr_tabs))
  end
end
