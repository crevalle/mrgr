defmodule Mrgr.Repo.Migrations.AddCommitsToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:commits, :map, default: "[]")
    end
  end
end
