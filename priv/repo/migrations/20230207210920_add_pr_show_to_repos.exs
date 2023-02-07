defmodule Mrgr.Repo.Migrations.AddPRShowToRepos do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add(:show_prs, :boolean, default: true)
    end

    create index(:repositories, :show_prs)
  end
end
