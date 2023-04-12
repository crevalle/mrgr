defmodule Mrgr.Repo.Migrations.ReplacePRKeyQuery do
  use Ecto.Migration

  def change do
    create index(:pull_requests, [:repository_id, :status])
  end
end
