defmodule Mrgr.Repo.Migrations.AddBigPRNotifiedStatusToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:notified_of_big_pr, :boolean, default: false)
    end
  end
end
