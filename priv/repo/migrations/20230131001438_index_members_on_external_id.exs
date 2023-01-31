defmodule Mrgr.Repo.Migrations.IndexMembersOnExternalId do
  use Ecto.Migration

  def change do
    create index(:members, :external_id)
  end
end
