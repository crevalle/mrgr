defmodule Mrgr.Repo.Migrations.CreateUserSnoozedPRsTable do
  use Ecto.Migration

  def change do
    create table(:user_snoozed_pull_requests) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:pull_request_id, references(:pull_requests, on_delete: :delete_all), null: false)

      add(:snoozed_until, :utc_datetime, null: false)

      timestamps()
    end

    create index(:user_snoozed_pull_requests, [:user_id, :pull_request_id])
    create index(:user_snoozed_pull_requests, [:pull_request_id, :user_id])

    create index(:user_snoozed_pull_requests, :snoozed_until)
  end
end
