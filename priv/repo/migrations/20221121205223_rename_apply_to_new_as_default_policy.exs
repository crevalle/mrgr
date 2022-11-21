defmodule Mrgr.Repo.Migrations.RenameApplyToNewAsDefaultPolicy do
  use Ecto.Migration

  def change do
    rename table(:repository_settings_policies), :apply_to_new_repos, to: :default
  end
end
