defmodule Mrgr.Repo.Migrations.AddAdditionsAndDeletionsToPRs do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:additions, :integer, default: 0)
      add(:deletions, :integer, default: 0)
    end
  end
end
