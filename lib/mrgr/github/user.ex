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

  def new(params) do
    keys =
      %__MODULE__{}
      |> Map.from_struct()
      |> Map.keys()

    %__MODULE__{}
    |> cast(params, keys)
    |> apply_changes()
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
