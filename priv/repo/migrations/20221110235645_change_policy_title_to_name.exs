defmodule Mrgr.Repo.Migrations.ChangePolicyTitleToName do
  use Ecto.Migration

  def change do
    rename table(:repository_settings_policies), :title, to: :name
  end
end
