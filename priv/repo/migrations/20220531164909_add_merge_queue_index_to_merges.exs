defmodule Mrgr.Repo.Migrations.AddPullRequestQueueIndexToPullRequests do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:merge_queue_index, :integer)
    end
  end
end
