defmodule Mrgr.Repo.Migrations.AddIndexesToMembers do
  use Ecto.Migration

  def change do
    create index(:members, :node_id, unique: true)
    create index(:members, :login, unique: true)
  end
end
