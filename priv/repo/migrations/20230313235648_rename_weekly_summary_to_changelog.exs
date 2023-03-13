defmodule Mrgr.Repo.Migrations.RenameWeeklySummaryToChangelog do
  use Ecto.Migration

  def change do
    rename table(:users), :send_weekly_summary_email, to: :send_weekly_changelog_email
  end
end
