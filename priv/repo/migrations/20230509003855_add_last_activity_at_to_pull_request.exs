defmodule Mrgr.Repo.Migrations.AddLastActivityAtToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:last_activity_at, :utc_datetime)
    end

    create index(:pull_requests, :last_activity_at)

  end
end
