defmodule Mrgr.UserTest do
  use Mrgr.DataCase

  describe "find_or_create_from_github/1" do
    test "creates a new user if the email is new" do
      user_data = github_oauth_user_data()
      token = oauth_token()

      user = Mrgr.User.find_or_create_from_github(user_data, token)
      assert user.id
      assert user.avatar_url
      assert user.nickname == user_data["login"]
      assert user.email == user_data["email"]
    end

    test "finds an existing user" do
      user_data = github_oauth_user_data()
      token = oauth_token()

      user = Mrgr.User.find_or_create_from_github(user_data, token)

      user_count = Mrgr.Repo.all(Mrgr.Schema.User) |> Enum.count()

      same_user = Mrgr.User.find_or_create_from_github(user_data, token)

      new_user_count = Mrgr.Repo.all(Mrgr.Schema.User) |> Enum.count()

      assert user.id == same_user.id
      assert new_user_count == user_count
    end
  end

  defp oauth_token do
    %OAuth2.AccessToken{
      access_token: "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",
      refresh_token: nil,
      expires_at: nil,
      token_type: "Bearer",
      other_params: %{"scope" => "read:org,repo,user:email"}
    }
  end

  defp github_oauth_user_data do
    # different on oauth than other places
    %{
      "avatar_url" => "https://avatars.githubusercontent.com/u/572921?v=4",
      "bio" => "Elixirist, founder of @empexconf, cohost of @ElixirTalk.  Pinball enthusiast. ",
      "blog" => "http://crevalle.io",
      "company" => "@crevalle",
      "created_at" => "2011-01-19T16:44:10Z",
      "email" => "desmond@crevalle.io",
      "events_url" => "https://api.github.com/users/desmondmonster/events{/privacy}",
      "followers" => 41,
      "followers_url" => "https://api.github.com/users/desmondmonster/followers",
      "following" => 4,
      "following_url" => "https://api.github.com/users/desmondmonster/following{/other_user}",
      "gists_url" => "https://api.github.com/users/desmondmonster/gists{/gist_id}",
      "gravatar_id" => "",
      "hireable" => nil,
      "html_url" => "https://github.com/desmondmonster",
      "id" => 572_921,
      "location" => "Los Angeles",
      "login" => "desmondmonster",
      "name" => "Desmond Bowe",
      "node_id" => "MDQ6VXNlcjU3MjkyMQ==",
      "organizations_url" => "https://api.github.com/users/desmondmonster/orgs",
      "public_gists" => 15,
      "public_repos" => 24,
      "received_events_url" => "https://api.github.com/users/desmondmonster/received_events",
      "repos_url" => "https://api.github.com/users/desmondmonster/repos",
      "site_admin" => false,
      "starred_url" => "https://api.github.com/users/desmondmonster/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/desmondmonster/subscriptions",
      "twitter_username" => nil,
      "type" => "User",
      "updated_at" => "2022-09-13T00:42:14Z",
      "url" => "https://api.github.com/users/desmondmonster"
    }
  end
end
