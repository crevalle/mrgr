defmodule Mrgr.Github.User do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:avatar_url, :string)
    field(:events_url, :string)
    field(:followers_url, :string)
    field(:following_url, :string)
    field(:gists_url, :string)
    field(:gravatar_id, :string)
    field(:html_url, :string)
    field(:id, :integer)
    field(:login, :string)
    # only in graphql
    field(:name, :string)
    field(:node_id, :string)
    field(:organizations_url, :string)
    field(:received_events_url, :string)
    field(:repos_url, :string)
    field(:site_admin, :boolean)
    field(:starred_url, :string)
    field(:subscriptions_url, :string)
    field(:type, :string)
    field(:url, :string)
  end

  @fields ~w[
    avatar_url
    events_url
    followers_url
    following_url
    gists_url
    gravatar_id
    html_url
    id
    login
    name
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

  def new(nil), do: nil

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_changes()
  end

  def from_member(member) do
    member
    |> Map.from_struct()
    |> new()
  end

  def changeset(schema, params) do
    cast(schema, params, @fields)
  end

  def graphql_to_attrs(list) when is_list(list) do
    Enum.map(list, &graphql_to_attrs/1)
  end

  def graphql_to_attrs(map) do
    %{
      "avatar_url" => map["avatarUrl"],
      "node_id" => map["id"],
      "id" => map["databaseId"],
      "login" => map["login"],
      "name" => map["name"]
    }
  end

  defmodule GraphQL do
    def git_actor do
      """
      avatarUrl
      date
      email
      name
      """
    end

    def actor do
      """
      avatarUrl
      login
      id
      """
    end

    def user do
      """
      avatarUrl
      databaseId
      id
      login
      name
      """
    end

    def team do
      """
      avatarUrl
      databaseId
      id
      name
      description
      slug
      """
    end

    def app do
      """
      databaseId
      description
      name
      slug
      """
    end
  end

  # %{
  # "avatar_url" => "https://avatars.githubusercontent.com/u/572921?v=4",
  # "events_url" => "https://api.github.com/users/desmondmonster/events{/privacy}",
  # "followers_url" => "https://api.github.com/users/desmondmonster/followers",
  # "following_url" => "https://api.github.com/users/desmondmonster/following{/other_user}",
  # "gists_url" => "https://api.github.com/users/desmondmonster/gists{/gist_id}",
  # "gravatar_id" => "",
  # "html_url" => "https://github.com/desmondmonster",
  # "id" => 572921,
  # "login" => "desmondmonster",
  # "node_id" => "MDQ6VXNlcjU3MjkyMQ==",
  # "organizations_url" => "https://api.github.com/users/desmondmonster/orgs",
  # "received_events_url" => "https://api.github.com/users/desmondmonster/received_events",
  # "repos_url" => "https://api.github.com/users/desmondmonster/repos",
  # "site_admin" => false,
  # "starred_url" => "https://api.github.com/users/desmondmonster/starred{/owner}{/repo}",
  # "subscriptions_url" => "https://api.github.com/users/desmondmonster/subscriptions",
  # "type" => "User",
  # "url" => "https://api.github.com/users/desmondmonster"
  # }
end
