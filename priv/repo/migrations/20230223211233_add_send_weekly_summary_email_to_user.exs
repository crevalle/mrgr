defmodule Mrgr.Repo.Migrations.AddSendWeeklySummaryEmailToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:send_weekly_summary_email, :boolean, default: true)
    end
  end
end
