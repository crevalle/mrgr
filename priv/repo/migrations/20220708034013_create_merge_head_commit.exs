defmodule Mrgr.Repo.Migrations.CreatePullRequestHeadCommit do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add :head_commit, :map, default: "{}"
    end
  end
end
