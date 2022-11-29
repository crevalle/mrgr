defmodule Mrgr.Repo.Migrations.MoveLabelNodeIDsToJoin do
  use Ecto.Migration

  def change do
    alter table(:labels) do
      remove(:node_id)
    end

    alter table(:label_repositories) do
      add(:node_id, :string)
    end

    create index(:label_repositories, :node_id, unique: true)
  end
end
