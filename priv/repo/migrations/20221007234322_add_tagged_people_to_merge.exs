defmodule Mrgr.Repo.Migrations.AddTaggedPeopleToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add(:assignees, :map, default: "[]")
      add(:requested_reviewers, :map, default: "[]")
    end
  end
end
