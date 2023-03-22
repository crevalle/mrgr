defmodule Mrgr.Repo.Migrations.AddDraftStatusToPRTab do
  use Ecto.Migration

  def change do
    alter table(:pr_tabs) do
      add(:draft_status, :string, default: "open")
    end
  end
end
