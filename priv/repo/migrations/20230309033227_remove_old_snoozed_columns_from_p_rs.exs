defmodule Mrgr.Repo.Migrations.RemoveOldSnoozedColumnsFromPRs do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      remove(:snoozed_until)
    end

  end
end
