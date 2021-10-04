defmodule Mrgr.Repo.Migrations.CreateRepositoriesLite do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add(:external_id, :integer)
      add(:full_name, :text)
      add(:name, :text)
      add(:node_id, :text)
      add(:private, :boolean)
      add(:data, :map)

      add(:installation_id, references(:installations, on_delete: :delete_all))
      timestamps()
    end

    create index(:repositories, :external_id)
    create index(:repositories, :installation_id)
  end
end
