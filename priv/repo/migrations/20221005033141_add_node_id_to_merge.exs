defmodule Mrgr.Repo.Migrations.AddNodeIdToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:node_id, :string)
    end

    create index(:merges, :node_id, unique: true)
  end
end
