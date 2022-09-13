defmodule Mrgr.Repo.Migrations.RelaxUserUrlsRequirement do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:urls, :map, null: true, from: :map)
    end
  end
end
