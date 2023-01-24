defmodule Mrgr.Repo.Migrations.RemoveSetupCompletedField do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      remove(:setup_completed, :boolean)
    end
  end
end
