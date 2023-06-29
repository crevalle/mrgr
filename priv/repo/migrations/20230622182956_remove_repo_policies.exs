defmodule Mrgr.Repo.Migrations.RemoveRepoPolicies do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      remove(:repository_settings_policy_id)
    end

    drop table(:repository_settings_policies)
  end
end
