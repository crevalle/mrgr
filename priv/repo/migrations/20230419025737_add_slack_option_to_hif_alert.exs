defmodule Mrgr.Repo.Migrations.AddSlackOptionToHIFAlert do
  use Ecto.Migration

  def change do
    rename table(:high_impact_file_rules), :notify_user, to: :notify_user_via_email

    alter table(:high_impact_file_rules) do
      add(:notify_user_via_slack, :boolean, default: false)
    end
  end
end
