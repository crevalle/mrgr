defmodule Mrgr.Repo.Migrations.AddNotifyUserToFileChangeAlert do
  use Ecto.Migration

  def change do
    alter table(:file_change_alerts) do
      add(:notify_user, :boolean, default: false, null: false)
    end
  end
end
