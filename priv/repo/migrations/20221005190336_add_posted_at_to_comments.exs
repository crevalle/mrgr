defmodule Mrgr.Repo.Migrations.AddPostedAtToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :posted_at, :utc_datetime
    end
  end
end
