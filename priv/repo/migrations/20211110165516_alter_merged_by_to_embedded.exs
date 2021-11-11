defmodule Mrgr.Repo.Migrations.AlterMergedByToEmbedded do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      remove(:merged_by)
      add(:merged_by, :map, default: "{}")
    end

  end
end
