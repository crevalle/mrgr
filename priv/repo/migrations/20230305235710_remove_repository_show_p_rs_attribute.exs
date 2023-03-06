defmodule Mrgr.Repo.Migrations.RemoveRepositoryShowPRsAttribute do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      remove(:show_prs)
    end
  end
end
