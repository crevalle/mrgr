defmodule Mrgr.Repo.Migrations.RemoveExternalIDFromRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      remove(:external_id)
    end
  end
end
