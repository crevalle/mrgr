defmodule Mrgr.Repo.Migrations.AddPullRequestReviewersJoin do
  use Ecto.Migration

  def change do
    create table(:pull_request_reviewers) do
      add(:pull_request_id, references(:pull_requests, on_delete: :delete_all), null: false)
      add(:member_id, references(:members, on_delete: :delete_all), null: false)

      timestamps()
    end

    create unique_index(:pull_request_reviewers, [:pull_request_id, :member_id])
    create index(:pull_request_reviewers, [:member_id, :pull_request_id])
  end
end
