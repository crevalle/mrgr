defmodule Mrgr.Repo.Migrations.AddUserNotificationEmail do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notification_email, :string)
    end
  end
end
