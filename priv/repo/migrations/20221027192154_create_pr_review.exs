defmodule Mrgr.Repo.Migrations.CreatePRReview do
  use Ecto.Migration

  def change do
    create table(:pr_reviews) do
      add(:merge_id, references(:merges))

      add(:state, :string, null: false)
      add(:node_id, :string, null: false)
      add(:commit_id, :string, null: false)
      add(:submitted_at, :utc_datetime)

      add(:data, :json)

      add(:user, :json)

      timestamps()
    end

    create index(:pr_reviews, :merge_id)
  end
end
