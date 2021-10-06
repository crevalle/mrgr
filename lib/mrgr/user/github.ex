defmodule Mrgr.User.Github do
  @spec generate_params(Ueberauth.Auth.t()) :: map()
  def generate_params(%{credentials: credentials, info: info} = _auth) do
    tokens = %{
      token: credentials.token,
      refresh_token: credentials.refresh_token,
      # utc
      token_expires_at: DateTime.from_unix!(credentials.expires_at)
    }

    info
    |> Map.from_struct()
    |> Map.merge(tokens)
    |> Map.put(:provider, "github")
  end

  def sync_organizations_and_repos(user) do
    client = Tentacat.Client.new(user.access_token)
  end
end
