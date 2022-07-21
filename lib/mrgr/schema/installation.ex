defmodule Mrgr.Schema.Installation do
  use Mrgr.Schema

  schema "installations" do
    field(:access_tokens_url, :string)
    field(:app_id, :integer)
    field(:app_slug, :string)
    field(:data, :map)
    field(:events, {:array, :string})
    field(:external_id, :integer)
    field(:html_url, :string)
    field(:installation_created_at, :utc_datetime)
    field(:permissions, :map)
    field(:repositories_url, :string)
    field(:repository_selection, :string)
    field(:target_id, :integer)
    field(:target_type, :string)
    field(:token, :string)
    field(:token_expires_at, :utc_datetime)

    belongs_to(:creator, Mrgr.Schema.User)
    has_one(:account, Mrgr.Schema.Account)
    has_many(:repositories, Mrgr.Schema.Repository)

    has_many(:incoming_webhooks, Mrgr.Schema.IncomingWebhook)

    has_many(:memberships, Mrgr.Schema.Membership)
    has_many(:members, through: [:memberships, :member])
    has_many(:users, through: [:members, :user])

    timestamps()
  end

  @create_params ~w[
    access_tokens_url
    app_id
    app_slug
    creator_id
    events
    external_id
    html_url
    installation_created_at
    data
    permissions
    repositories_url
    repository_selection
    target_id
    target_type
  ]a

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @create_params)
    |> cast_assoc(:account)
    |> cast_assoc(:repositories)
    |> foreign_key_constraint(:creator_id)
    |> put_external_id()
    |> put_data_map()
  end

  @tokens ~w[
    token
    token_expires_at
  ]a

  def tokens_changeset(schema, params) do
    schema
    |> cast(params, @tokens)
    |> validate_required(@tokens)
  end

  # "access_tokens_url" => "https://api.github.com/app/installations/19872469/access_tokens",
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
  # "app_id" => 139973,
  # "app_slug" => "get-mrgr",
  # "created_at" => "2021-10-02T21:59:58.000-07:00",
  # "events" => ["check_run", "check_suite", "create", "pull_request",
  # "pull_request_review"],
  # "has_multiple_single_files" => false,
  # "html_url" => "https://github.com/organizations/crevalle/settings/installations/19872469",
  # "id" => 19872469,
  # "permissions" => %{
  # "administration" => "read",
  # "checks" => "write",
  # "contents" => "read",
  # "issues" => "write",
  # "members" => "read",
  # "metadata" => "read",
  # "pull_requests" => "write"
  # },
  # "repositories_url" => "https://api.github.com/installation/repositories",
  # "repository_selection" => "all",
  # "single_file_name" => nil,
  # "single_file_paths" => [],
  # "suspended_at" => nil,
  # "suspended_by" => nil,
  # "target_id" => 7728671,
  # "target_type" => "Organization",
  # "updated_at" => "2021-10-02T21:59:58.000-07:00"
  # },
end
