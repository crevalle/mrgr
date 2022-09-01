defmodule Mrgr.Repo.Migrations.AddLastSeenToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_seen_at, :utc_datetime
    end
  end
end
