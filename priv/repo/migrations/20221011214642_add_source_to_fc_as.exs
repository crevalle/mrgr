defmodule Mrgr.Repo.Migrations.AddSourceToFCAs do
  use Ecto.Migration

  def change do
    alter table(:file_change_alerts) do
      add(:source, :text)
    end
  end
end
