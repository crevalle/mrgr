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

  # new installation.  users should get a token immediately upon creation
  def token_expired?(%{token: nil}), do: true
  # user tokens don't expire, ie, have a token_expires_at.  But we expect there to be a token.
  def token_expired?(%User{token_expires_at: nil, token: token}) when is_bitstring(token),
    do: false

  def token_expired?(%Installation{token_expires_at: nil}), do: true

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
    Mrgr.Github.API.get_new_installation_token(client, id)
  end

  # assumes token is fresh!
  def clientize(%{token: token}) do
    Tentacat.Client.new(%{access_token: token})
  end
end
