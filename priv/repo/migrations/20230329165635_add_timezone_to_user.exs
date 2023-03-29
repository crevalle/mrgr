defmodule Mrgr.Repo.Migrations.AddTimezoneToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:timezone, :string, default: "Etc/UTC")
    end
  end
end
