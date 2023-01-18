defmodule Mrgr.Repo.Migrations.RicherInstallationState do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:state, :string, default: "created")
    end
  end
end
