defmodule Mrgr.Schema.Account do
  use Mrgr.Schema

  schema "accounts" do
    field(:avatar_url, :string)
    field(:data, :map)
    field(:events_url, :string)
    field(:external_id, :integer)
    field(:followers_url, :string)
    field(:following_url, :string)
    field(:gists_url, :string)
    field(:gravatar_id, :string)
    field(:html_url, :string)
    field(:login, :string)
    field(:node_id, :string)
    field(:organizations_url, :string)
    field(:received_events_url, :string)
    field(:repos_url, :string)
    field(:site_admin, :boolean)
    field(:starred_url, :string)
    field(:subscriptions_url, :string)
    field(:type, :string)
    field(:url, :string)

    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  @allowed ~w[
    avatar_url
    data
    events_url
    external_id
    followers_url
    following_url
    gists_url
    gravatar_id
    html_url
    login
    node_id
    organizations_url
    received_events_url
    repos_url
    site_admin
    starred_url
    subscriptions_url
    type
    url
  ]a

  def changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> foreign_key_constraint(:installation_id)
    |> put_external_id()
    |> put_data_map()
  end

  # "account" => %{
  # "avatar_url" => "https://avatars.githubusercontent.com/u/7728671?v=4",
  # "events_url" => "https://api.github.com/users/crevalle/events{/privacy}",
  # "followers_url" => "https://api.github.com/users/crevalle/followers",
  # "following_url" => "https://api.github.com/users/crevalle/following{/other_user}",
  # "gists_url" => "https://api.github.com/users/crevalle/gists{/gist_id}",
  # "gravatar_id" => "",
  # "html_url" => "https://github.com/crevalle",
  # "id" => 7728671,
  # "login" => "crevalle",
  # "node_id" => "MDEyOk9yZ2FuaXphdGlvbjc3Mjg2NzE=",
  # "organizations_url" => "https://api.github.com/users/crevalle/orgs",
  # "received_events_url" => "https://api.github.com/users/crevalle/received_events",
  # "repos_url" => "https://api.github.com/users/crevalle/repos",
  # "site_admin" => false,
  # "starred_url" => "https://api.github.com/users/crevalle/starred{/owner}{/repo}",
  # "subscriptions_url" => "https://api.github.com/users/crevalle/subscriptions",
  # "type" => "Organization",
  # "url" => "https://api.github.com/users/crevalle"
  # },
end
