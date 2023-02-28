defmodule Mrgr.Repo.Migrations.AddNodeIdIndexToUsers do
  use Ecto.Migration

  def change do
    create index(:users, :node_id, unique: true)
  end
end
