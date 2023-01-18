defmodule Mrgr.Repo.Migrations.AddCascadingDeletesToInstallationResources do
  use Ecto.Migration

  def change do
    drop constraint(:incoming_webhooks, :incoming_webhooks_installation_id_fkey)

    alter table(:incoming_webhooks) do
      modify(:installation_id, references(:installations, on_delete: :delete_all))
    end

    drop constraint(
           :repository_settings_policies,
           :repository_security_profiles_installation_id_fkey
         )

    alter table(:repository_settings_policies) do
      modify(:installation_id, references(:installations, on_delete: :delete_all))
    end

    drop constraint(:pull_requests, :pull_requests_repository_id_fkey)

    alter table(:pull_requests) do
      modify(:repository_id, references(:repositories, on_delete: :delete_all))
    end

    drop constraint(:high_impact_files, :file_change_alerts_repository_id_fkey)

    alter table(:high_impact_files) do
      modify(:repository_id, references(:repositories, on_delete: :delete_all))
    end

    drop constraint(:comments, :comments_pull_request_id_fkey)

    alter table(:comments) do
      modify(:pull_request_id, references(:pull_requests, on_delete: :delete_all))
    end
  end
end
