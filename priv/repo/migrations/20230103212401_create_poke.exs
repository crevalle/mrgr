defmodule Mrgr.Repo.Migrations.CreatePoke do
  use Ecto.Migration

  def change do
    create table(:pokes) do
      add :sender_id, references(:users)
      add :pull_request_id, references(:pull_requests, on_delete: :delete_all)

      add :type, :string
      add :message, :string

      add :node_id, :string
      add :url, :string

      timestamps()
    end

    create index(:pokes, :pull_request_id)
    create index(:pokes, :sender_id)
    create index(:pokes, :node_id)
  end
end
