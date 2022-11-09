defmodule Mrgr.Repo.Migrations.AssociatePoliciesWithRepos do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add(:repository_security_profile_id, references(:repository_security_profiles))
    end

    create index(:repositories, :repository_security_profile_id)
  end
end
