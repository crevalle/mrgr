defmodule Mrgr.Repo.Migrations.AssociatePRsWithLabels do
  use Ecto.Migration

  def change do
    create table(:pull_request_labels) do
      add(:label_id, references(:labels, on_delete: :delete_all))
      add(:pull_request_id, references(:pull_requests, on_delete: :delete_all))

      timestamps()
    end

    create index(:pull_request_labels, [:label_id, :pull_request_id], unique: true)
    create index(:pull_request_labels, [:pull_request_id, :label_id])
  end
end
