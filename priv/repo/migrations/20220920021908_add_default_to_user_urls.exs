defmodule Mrgr.Repo.Migrations.AddDefaultToUserUrls do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :urls, :map, default: "{}"
    end
  end
end
