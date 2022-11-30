defmodule Mrgr.Repo.Migrations.AddTagsToPRs do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:labels, :map, default: "[]")
    end
  end
end
