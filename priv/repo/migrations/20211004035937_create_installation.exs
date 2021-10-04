defmodule Mrgr.Repo.Migrations.CreateInstallation do
  use Ecto.Migration

  def change do
    create table(:installations) do
      add(:access_tokens_url, :text)
      add(:app_id, :integer)
      add(:app_slug, :text)
      add(:installation_created_at, :utc_datetime)
      add(:events, {:array, :text})
      add(:html_url, :text)
      add(:external_id, :integer)
      add(:permissions, :map)
      add(:repositories_url, :text)
      add(:repository_selection, :text)
      add(:target_id, :integer)
      add(:target_type, :text)
      add(:data, :map)

      add(:creator_id, references(:users, on_delete: :delete_all))
      timestamps()
    end

    create index(:installations, :external_id)
  end
end
