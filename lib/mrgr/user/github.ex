defmodule Mrgr.User.Github do
  @spec generate_params(%{required(String.t()) => any()}, OAuth2.AccessToken.t()) :: map()
  def generate_params(user_data, access_token) do
    token_data = token_params(access_token)

    Map.merge(user_data, token_data)
  end

  def token_params(%OAuth2.AccessToken{} = token) do
    # %OAuth2.AccessToken{
    #   access_token: "ghu_SDm4hpJMBX02vO6ujeGJNILKAkxaee0sunCV",
    #   expires_at: 1634722596,
    #   other_params: %{"refresh_token_expires_in" => "15724800", "scope" => ""},
    #   refresh_token: "ghr_pt6dag0OHncrMh10BxPTt1Sl3lXxIRQPABZJbUWGHDp47juR214JpkNS0eRN5Eq03dZEUa3ipukj",
    #   token_type: "Bearer"
    # }

    %{
      "token" => token.access_token,
      "refresh_token" => token.refresh_token,
      "token_expires_at" => safe_datetime_parse(token.expires_at)
    }
  end

  def token_params(credentials) do
    %{
      "token" => credentials.token,
      "refresh_token" => credentials.refresh_token,
      "token_expires_at" => safe_datetime_parse(credentials.expires_at)
    }
  end

  # user oauth tokens don't expire
  defp safe_datetime_parse(nil), do: nil
  defp safe_datetime_parse(dt), do: DateTime.from_unix!(dt)
end
