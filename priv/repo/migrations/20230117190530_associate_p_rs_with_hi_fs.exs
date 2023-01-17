defmodule Mrgr.Repo.Migrations.AssociatePRsWithHIFs do
  use Ecto.Migration

  def change do
    create table(:high_impact_file_pull_requests) do
      add(:pull_request_id, references(:pull_requests, on_delete: :delete_all), null: false)

      add(:high_impact_file_id, references(:high_impact_files, on_delete: :delete_all),
        null: false
      )

      timestamps
    end

    create index(:high_impact_file_pull_requests, [:pull_request_id, :high_impact_file_id],
             unique: true
           )

    create index(:high_impact_file_pull_requests, [:high_impact_file_id, :high_impact_file_id],
             unique: true
           )
  end
end
