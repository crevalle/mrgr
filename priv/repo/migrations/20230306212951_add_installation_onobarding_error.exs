defmodule Mrgr.Repo.Migrations.AddInstallationOnobardingError do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add(:onboarding_error, :text)
    end
  end
end
