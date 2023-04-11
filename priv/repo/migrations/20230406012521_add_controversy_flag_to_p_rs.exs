defmodule Mrgr.Repo.Migrations.AddControversyFlagToPRs do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add(:controversial, :boolean, default: false)
    end

  end
end
