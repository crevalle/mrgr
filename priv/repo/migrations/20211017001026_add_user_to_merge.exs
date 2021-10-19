defmodule Mrgr.Repo.Migrations.AddUserToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
priv/repo/migrations/20211017001026_add_user_to_merge.exs      add(:user, :map, default: "{}")
    end
  end
end
