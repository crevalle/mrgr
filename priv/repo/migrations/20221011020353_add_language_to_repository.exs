defmodule Mrgr.Repo.Migrations.AddLanguageToRepository do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :language, :string
    end
  end
end
