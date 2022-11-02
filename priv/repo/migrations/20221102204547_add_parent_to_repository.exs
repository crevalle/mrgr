defmodule Mrgr.Repo.Migrations.AddParentToRepository do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add(:parent, :map, default: "{}")
    end
  end
end
