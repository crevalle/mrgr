defmodule Mrgr.Repo.Migrations.AddNodeIDToLabels do
  use Ecto.Migration

  def change do
    alter table(:labels) do
      add(:node_id, :string)
    end

    create index(:labels, :node_id, unique: true)
  end
end
