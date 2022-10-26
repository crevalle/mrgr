defmodule Mrgr.Repo.Migrations.AddRequiredReviewsToRepository do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :dismiss_stale_reviews, :boolean, default: true, null: false
      add :require_code_owner_reviews, :boolean, default: true, null: false
      add :required_approving_review_count, :integer, default: 0
    end
  end
end
