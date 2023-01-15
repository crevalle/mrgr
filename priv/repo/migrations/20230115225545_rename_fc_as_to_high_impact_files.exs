defmodule Mrgr.Repo.Migrations.RenameFCAsToHighImpactFiles do
  use Ecto.Migration

  def change do
    rename table("file_change_alerts"), to: table("high_impact_files")
  end
end
