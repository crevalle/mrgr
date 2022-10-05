defmodule Mrgr.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :merge_id, references(:merges, on_delete: :delete_all), null: false
      add :object, :string

      add :raw, :map, default: "{}"

      timestamps()
    end
  end
end
