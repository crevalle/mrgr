defmodule Mrgr.Repo.Migrations.RemoveTypeFromPoke do
  use Ecto.Migration

  def change do
    alter table(:pokes) do
      remove(:type)
    end
  end
end
