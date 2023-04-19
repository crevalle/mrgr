defmodule Mrgr.Repo.Migrations.RenameHIFChannelsToLineUpWithPreferences do
  use Ecto.Migration

  def change do
    rename table(:high_impact_file_rules), :notify_user_via_email, to: :email
    rename table(:high_impact_file_rules), :notify_user_via_slack, to: :slack
  end
end
