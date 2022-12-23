defmodule Mrgr.Repo.Migrations.ReAddPRExternalIDIndex do
  use Ecto.Migration

  def change do
    create index(:pull_requests, :external_id, unique: true)
  end
end
