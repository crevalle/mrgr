defmodule Mrgr.Repo.Migrations.AddUserIdToHIF do
  use Ecto.Migration

  def change do
    alter table("high_impact_files") do
      add(:user_id, references(:users, on_delete: :delete_all))
    end
  end
end
