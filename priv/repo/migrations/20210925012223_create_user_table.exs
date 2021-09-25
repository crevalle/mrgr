defmodule Mrgr.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:birthday, :text)
      add(:description, :text)
      add(:email, :text, null: false)
      add(:first_name, :text)
      add(:image, :text)
      add(:last_name, :text)
      add(:location, :text)
      add(:name, :text)
      add(:nickname, :text)
      add(:phone, :text)
      add(:provider, :text, null: false)
      add(:refresh_token, :text, null: false)
      add(:token, :text, null: false)
      add(:token_expires_at, :utc_datetime, null: false)

      add(:urls, :map, null: false)

      timestamps()
    end

    create unique_index(:users, :email)
    create unique_index(:users, :nickname)
  end
end
