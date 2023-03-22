defmodule Mrgr.Repo.Migrations.AddDrafttoPullReuqest do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:draft, :boolean, default: false)
    end
  end
end
