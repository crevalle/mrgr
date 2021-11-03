defmodule Mrgr.Repo.Migrations.AddMemberDeleteCascadeToUsers do
  use Ecto.Migration

  def change do
    drop constraint(:members, "members_user_id_fkey")

    alter table(:members) do
      modify(:user_id, references(:users, on_delete: :nilify_all))
    end

  end
end
