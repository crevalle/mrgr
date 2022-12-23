defmodule Mrgr.Repo.Migrations.AddCIStatusToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add :ci_status, :string
    end
  end
end
