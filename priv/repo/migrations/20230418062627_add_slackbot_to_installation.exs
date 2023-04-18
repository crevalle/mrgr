defmodule Mrgr.Repo.Migrations.AddSlackbotToInstallation do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add :slackbot, :map
    end
  end
end
