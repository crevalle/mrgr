defmodule Mrgr.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add(:description, :string)
      add(:external_id, :integer)
      add(:html_url, :string)
      add(:members_url, :string)
      add(:name, :string)
      add(:node_id, :string)

      add(:permission, :string)
      add(:privacy, :string)
      add(:repositories_url, :string)
      add(:slug, :string)
      add(:url, :string)

      add(:installation_id, references(:installations, on_delete: :delete_all))

      timestamps()
    end

    create index(:teams, :installation_id)
    create index(:teams, :node_id, unique: true)
  end
end
