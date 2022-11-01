defmodule Mrgr.Repo.Migrations.AddPullRequestFreezeToRepository do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :merge_freeze_enabled, :boolean, default: false, null: false
    end
  end
end
