defmodule Mrgr.Repo.Migrations.UpdatePolicyName do
  use Ecto.Migration

  def change do
    rename table(:repository_security_profiles), to: table(:repository_settings_policies)

    rename table(:repositories), :repository_security_profile_id,
      to: :repository_settings_policy_id
  end
end
