defmodule Mrgr.Repo.Migrations.RemovePRTabPosition do
  use Ecto.Migration

  def change do
    alter table(:label_pr_tabs) do
      remove(:position)
    end
  end
end
