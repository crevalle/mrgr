defmodule Mrgr.User.Github do
  @spec generate_params(Ueberauth.Auth.t()) :: map()
  def generate_params(%{credentials: credentials, info: info} = _auth) do
    tokens = token_params(credentials)

    info
    |> Map.from_struct()
    |> Map.merge(tokens)
    |> Map.put(:provider, "github")
  end

  def token_params(%OAuth2.AccessToken{} = params) do
    # TODO: maybe pull refresh_token_expires_in
    # %OAuth2.AccessToken{
    #   access_token: "ghu_SDm4hpJMBX02vO6ujeGJNILKAkxaee0sunCV",
    #   expires_at: 1634722596,
    #   other_params: %{"refresh_token_expires_in" => "15724800", "scope" => ""},
    #   refresh_token: "ghr_pt6dag0OHncrMh10BxPTt1Sl3lXxIRQPABZJbUWGHDp47juR214JpkNS0eRN5Eq03dZEUa3ipukj",
    #   token_type: "Bearer"
    # }

    %{
      token: params.access_token,
      refresh_token: params.refresh_token,
      token_expires_at: DateTime.from_unix!(params.expires_at)
    }
  end

  def token_params(credentials) do
    %{
      token: credentials.token,
      refresh_token: credentials.refresh_token,
      # utc
      token_expires_at: DateTime.from_unix!(credentials.expires_at)
    }
  end
end
