defmodule Mrgr.Repo.Migrations.AddInstallingSlackRedirectToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:installing_slackbot_from_profile_page, :boolean, default: false)
    end
  end
end
