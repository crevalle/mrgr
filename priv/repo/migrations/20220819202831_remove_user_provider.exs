defmodule Mrgr.Repo.Migrations.RemoveUserProvider do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove(:provider)
    end
  end

  def down do
    alter table(:users) do
      add(:provider, :string)
    end
  end
end
