defmodule Mrgr.Repo.Migrations.AddNameToSecurityProfile do
  use Ecto.Migration

  def change do
    alter table(:repository_security_profiles) do
      add(:title, :text)
    end
  end
end
