defmodule Mrgr.Repo.Migrations.CreateNotificationRecord do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add(:channel, :text, null: false)
      add(:type, :text, null: false)
      add(:error, :text)

      add(:recipient_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:notifications, :recipient_id)
  end
end
