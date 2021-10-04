defmodule Mrgr.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add(:avatar_url, :text)
      add(:events_url, :text)
      add(:followers_url, :text)
      add(:following_url, :text)
      add(:gists_url, :text)
      add(:gravatar_id, :text)
      add(:html_url, :text)
      add(:external_id, :integer)
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
      add(:data, :map)

      add(:installation_id, references(:installations, on_delete: :delete_all))
      timestamps()
    end

    create index(:accounts, :external_id)
    create index(:accounts, :installation_id)
  end
end
