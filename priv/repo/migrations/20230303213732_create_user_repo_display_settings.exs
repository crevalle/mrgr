defmodule Mrgr.Repo.Migrations.CreateUserRepoDisplaySettings do
  use Ecto.Migration

  def change do
    create table(:user_visible_repositories) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:repository_id, references(:repositories, on_delete: :delete_all))

      timestamps()
    end

    create index(:user_visible_repositories, [:user_id, :repository_id], unique: true)
    create index(:user_visible_repositories, [:repository_id, :user_id])
  end
end
