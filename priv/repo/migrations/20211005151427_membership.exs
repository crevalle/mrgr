defmodule Mrgr.Repo.Migrations.Membership do
  use Ecto.Migration

  def change do
    create table(:memberships) do
      add(:member_id, references(:members), on_delete: :delete_all)
      add(:installation_id, references(:installations), on_delete: :delete_all)
      add(:active, :boolean, default: true)

      timestamps()
    end

    create index(:memberships, [:member_id, :installation_id], unique: true)
    create index(:memberships, [:installation_id, :member_id], unique: true)
  end
end
