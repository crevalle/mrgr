defmodule Mrgr.Repo.Migrations.AddChannelsToPRTabs do
  use Ecto.Migration

  def change do
    alter table(:pr_tabs) do
      add(:email, :boolean, default: true)
      add(:slack, :boolean, default: false)
    end
  end
end
