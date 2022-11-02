defmodule Mrgr.Repo.Migrations.IndexReposOnNodeId do
  use Ecto.Migration

  def change do
    create index(:repositories, :node_id, unique: true)
  end
end
