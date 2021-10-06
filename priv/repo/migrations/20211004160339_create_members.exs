defmodule Mrgr.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      add(:avatar_url, :text)
      add(:events_url, :text)
      add(:external_id, :integer)
      add(:followers_url, :text)
      add(:following_url, :text)
      add(:gists_url, :text)
      add(:gravatar_id, :text)
      add(:html_url, :text)
      add(:login, :text)
      add(:node_id, :text)
      add(:organizations_url, :text)
      add(:received_events_url, :text)
      add(:repos_url, :text)
      add(:site_admin, :boolean)
      add(:starred_url, :text)
      add(:subscriptions_url, :text)
      add(:type, :text)
      add(:url, :text)

      # do not add on_delete: :delete_all since quitting our
      # app means they may still be a member of something
      add(:user_id, references(:users))
      timestamps()
    end

    create index(:members, :user_id)
  end
end
