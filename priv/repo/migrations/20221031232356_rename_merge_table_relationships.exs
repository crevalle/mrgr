defmodule Mrgr.Repo.Migrations.RenameMergeTableRelationships do
  use Ecto.Migration

  def up do
    drop constraint(:merges, "merges_author_id_fkey")
    drop constraint(:merges, "merges_merged_by_id_fkey")
    drop constraint(:merges, "merges_repository_id_fkey")

    rename table(:merges), to: table(:pull_requests)

    alter table(:pull_requests) do
      # "Modifying" the columns rengenerates the constraints with the correct
      # new names. These were the same types and options the columns were
      # originally created with in previous migrations.
      modify :author_id, references(:members)
      modify :merged_by_id, references(:members)
      modify :repository_id, references(:repositories)
    end

    execute "ALTER INDEX merges_pkey RENAME TO pull_requests_pkey"
    execute "ALTER INDEX merges_node_id_index RENAME TO pull_requests_node_id_index"
    execute "ALTER INDEX merges_repository_id_index RENAME TO pull_requests_repository_id_index "
    execute "ALTER SEQUENCE merges_id_seq RENAME TO pull_requests_id_seq;"

    ## Other tables

    drop constraint(:checklists, "checklists_merge_id_fkey")
    drop constraint(:comments, "comments_merge_id_fkey")
    drop constraint(:pr_reviews, "pr_reviews_merge_id_fkey")

    rename table(:checklists), :merge_id, to: :pull_request_id
    rename table(:comments), :merge_id, to: :pull_request_id
    rename table(:pr_reviews), :merge_id, to: :pull_request_id

    alter table(:checklists) do
      modify :pull_request_id, references(:pull_requests)
    end

    alter table(:comments) do
      modify :pull_request_id, references(:pull_requests)
    end

    alter table(:pr_reviews) do
      modify :pull_request_id, references(:pull_requests)
    end
  end

  def down do
    # no going back
  end
end
