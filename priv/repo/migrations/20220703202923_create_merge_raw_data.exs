defmodule Mrgr.Repo.Migrations.CreateMergeRawData do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:raw, :map, default: "{}")
    end
  end
end
