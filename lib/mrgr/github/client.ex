defmodule Mrgr.Github.Client do
  alias Mrgr.Schema.{Installation, User}

  @spec new(Installation.t() | User.t()) :: Tentacat.Client.t()
  def new(actor) do
    case token_expired?(actor) do
      true ->
        actor
        |> refresh_token!()
        |> clientize()

      false ->
        clientize(actor)
    end
  end

  def token_expired?(%{token: nil, token_expires_at: _e}), do: true
  def token_expired?(%{token: _t, token_expires_at: nil}), do: true

  def token_expired?(%{token_expires_at: expires}) do
    Mrgr.DateMath.in_the_past?(expires)
  end

  def refresh_token!(%User{} = user) do
    token = request_new_token(user)

    Mrgr.User.set_tokens(user, token)
  end

  def refresh_token!(%Installation{} = install) do
    token = request_new_token(install)

    Mrgr.Installation.set_tokens(install, token)
  end

  def request_new_token(%User{} = user) do
    opts = [
      params: %{"refresh_token" => user.refresh_token},
      strategy: OAuth2.Strategy.Refresh
    ]

    {:ok, %{token: token}} =
      opts
      |> Ueberauth.Strategy.Github.OAuth.client()
      |> OAuth2.Client.get_token()

    Mrgr.User.Github.token_params(token)
  end

  def request_new_token(%{external_id: id} = _installation) do
    jwt = Mrgr.Github.JwtToken.signed_jwt()

    client = Tentacat.Client.new(%{jwt: jwt})
    response = Tentacat.App.Installations.token(client, id)
    Mrgr.Github.parse_into(response, Mrgr.Github.AccessToken)
  end

  # assumes token is fresh!
  def clientize(%{token: token}) do
    Tentacat.Client.new(%{access_token: token})
  end
end
