defmodule Mrgr.Repo.Migrations.AddPullRequestableStatesToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add :mergeable, :string
      add :merge_state_status, :string
    end
  end
end
