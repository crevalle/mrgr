defmodule Mrgr.Repo.Migrations.AddUserToPullRequest do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:user, :map, default: "{}")
    end
  end
end
