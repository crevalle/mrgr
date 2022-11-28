defmodule Mrgr.Repo.Migrations.FixLabelRepositoryIndex do
  use Ecto.Migration

  def change do
    drop index(:label_repositories, [:repository_id, :repository_id], unique: true)
    create index(:label_repositories, [:repository_id, :label_id], unique: true)
  end
end
