defmodule Mrgr.Repo.Migrations.CreateWaitingListSignup do
  use Ecto.Migration

  def change do
    create table(:waiting_list_signups) do
      add :email, :string, null: false

      timestamps()
    end
  end
end
