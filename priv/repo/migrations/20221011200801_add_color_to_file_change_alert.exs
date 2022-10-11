defmodule Mrgr.Repo.Migrations.AddColorToFileChangeAlert do
  use Ecto.Migration

  def change do
    alter table(:file_change_alerts) do
      add(:bg_color, :string)
    end
  end
end
