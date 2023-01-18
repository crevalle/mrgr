defmodule Auth.GitHub do
  use OAuth2.Strategy

  # Public API

  def client do
    OAuth2.Client.new(
      strategy: __MODULE__,
      # warning - read at compile time.  probably should change this
      client_id: Application.get_env(:mrgr, :oauth)[:client_id],
      client_secret: Application.get_env(:mrgr, :oauth)[:client_secret],
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token"
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  def authorize_url! do
    OAuth2.Client.authorize_url!(client(), scope: "user:email")
  end

  # you can pass options to the underlying http library via `opts` parameter
  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    client()
    |> OAuth2.Client.get_token!(params, headers, opts)
    # Github requires API requests to have a user agent header
    # OAuth2.Client.get_token!/4 resets our headers so we put
    # the user agent here, not in the constructor
    |> put_header("User-Agent", "Mrgr")
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
