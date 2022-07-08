defmodule Mrgr.Repo.Migrations.CreateMergeHeadCommit do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add :head_commit, :map, default: "{}"
    end
  end
end
