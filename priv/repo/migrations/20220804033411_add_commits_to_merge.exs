defmodule Mrgr.Repo.Migrations.AddCommitsToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:commits, :map, default: "[]")
    end
  end
end
