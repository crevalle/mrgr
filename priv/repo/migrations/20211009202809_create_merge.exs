defmodule Mrgr.Repo.Migrations.CreatePullRequest do
  use Ecto.Migration

  def change do
    create table(:merges) do
      add(:title, :text)
      add(:external_id, :integer)
      add(:url, :text)

      add(:number, :integer)

      add(:status, :text)

      add(:opened_at, :utc_datetime)

      add(:repository_id, references(:repositories, on_delete: :delete_all))

      add(:author_id, references(:members))

      add(:merged_by_id, references(:members))
      add(:merged_at, :utc_datetime)

      timestamps()
    end

    create index(:merges, :repository_id)
  end
end
