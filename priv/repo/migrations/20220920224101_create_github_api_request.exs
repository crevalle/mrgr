defmodule Mrgr.Repo.Migrations.CreateGithubAPIRequest do
  use Ecto.Migration

  def change do
    create table(:github_api_requests) do
      add(:installation_id, references(:installations, on_delete: :delete_all))

      add(:api_call, :text, null: false)
      add(:response_code, :integer)
      add(:elapsed_time, :integer)
      add(:data, :map, default: "{}")
      add(:response_headers, :map, default: "{}")

      timestamps()
    end

    create index(:github_api_requests, :installation_id)
  end
end
