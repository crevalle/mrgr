defmodule Mrgr.Repo.Migrations.AddMissingIndexesForPRs do
  use Ecto.Migration

  def change do
    create index(:comments, :pull_request_id)
    create index(:pull_requests, :status)

  end
end
