defmodule Mrgr.Repo.Migrations.CreatePRNotificationsJoin do
  use Ecto.Migration

  def change do
    create table(:notifications_pull_requests) do
      add(:pull_request_id, references(:pull_requests, on_delete: :delete_all), null: false)
      add(:notification_id, references(:notifications, on_delete: :delete_all), null: false)

      timestamps
    end

    create index(:notifications_pull_requests, [:pull_request_id, :notification_id], unique: true)
    create index(:notifications_pull_requests, [:notification_id, :pull_request_id])
  end
end
