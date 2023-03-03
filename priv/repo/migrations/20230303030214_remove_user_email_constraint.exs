defmodule Mrgr.Repo.Migrations.RemoveUserEmailConstraint do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:email, :string, null: true, from: :string)
    end
  end
end
