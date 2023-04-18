defmodule Mrgr.Repo.Migrations.CreateUserNotificationAddresses do
  use Ecto.Migration

  def change do
    create table(:user_notification_addresses) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:installation_id, references(:installations, on_delete: :delete_all))

      add(:email, :string)
      add(:slack_id, :string)

      timestamps()
    end

    create index(:user_notification_addresses, [:user_id, :installation_id], unique: true)
  end
end
