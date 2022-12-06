defmodule Mrgr.Repo.Migrations.RemoveEmbeddedLabelsColumn do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      remove(:labels)
    end
  end
end
