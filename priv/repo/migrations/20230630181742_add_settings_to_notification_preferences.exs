defmodule Mrgr.Repo.Migrations.AddSettingsToNotificationPreferences do
  use Ecto.Migration

  def change do
    alter table(:user_notification_preferences) do
      add(:settings, :map, default: "{}")
    end
  end
end
