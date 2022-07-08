defmodule Mrgr.Repo.Migrations.AddFilesChangedToMerge do
  use Ecto.Migration

  def change do
    alter table(:merges) do
      add :files_changed, {:array, :string}, default: []
    end
  end
end
