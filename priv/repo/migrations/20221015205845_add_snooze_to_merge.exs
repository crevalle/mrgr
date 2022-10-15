defmodule Mrgr.Repo.Migrations.AddSnoozeToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:snoozed_until, :utc_datetime)
    end
  end
end
