defmodule Mrgr.Repo.Migrations.RemoveMergeQueue do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      remove(:merge_queue_index)
    end
  end
end
