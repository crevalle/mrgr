defmodule Mrgr.Repo.Migrations.AddTokenToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:token, :text)
      add(:token_expires_at, :utc_datetime)
    end
  end
end
