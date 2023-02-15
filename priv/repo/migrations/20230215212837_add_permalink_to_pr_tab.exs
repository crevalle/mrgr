defmodule Mrgr.Repo.Migrations.AddPermalinkToPRTab do
  use Ecto.Migration

  def change do
    alter table(:pr_tabs) do
      add(:permalink, :string)
    end
  end
end
