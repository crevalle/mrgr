defmodule Mrgr.Repo.Migrations.CreateUserNotificationPreferences do
  use Ecto.Migration

  def change do
    create table(:user_notification_preferences) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:installation_id, references(:installations, on_delete: :delete_all), null: false)

      add(:event, :string, null: false)

      add(:email, :boolean, default: false, null: false)
      add(:slack, :boolean, default: false, null: false)

      timestamps()
    end

    create index(:user_notification_preferences, [:user_id, :installation_id, :event],
             unique: true
           )
  end
end
