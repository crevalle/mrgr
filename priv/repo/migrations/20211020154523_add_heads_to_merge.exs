defmodule Mrgr.Repo.Migrations.AddHeadsToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:head, :map, default: "{}")
    end

  end
end
