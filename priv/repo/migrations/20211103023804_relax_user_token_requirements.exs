defmodule Mrgr.Repo.Migrations.RelaxUserTokenRequirements do
  use Ecto.Migration

  def change do
    alter table(:users) do
     modify(:refresh_token, :text, null: true, from: :text)
     modify(:token_expires_at, :utc_datetime, null: true, from: :utc_datetime)
    end

  end
end
