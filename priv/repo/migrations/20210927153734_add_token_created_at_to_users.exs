defmodule Mrgr.Repo.Migrations.AddTokenCreatedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :token_updated_at, :utc_datetime
    end
  end
end
