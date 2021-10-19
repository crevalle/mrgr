defmodule Mrgr.Github.Client do
  alias Mrgr.Schema.{Installation, User}

  @spec new(Installation.t()) :: Tentacat.Client.t()
  def new(%Installation{} = install) do
    case token_expired?(install) do
      true ->
        install
        |> refresh_token!()
        |> clientize()

      false ->
        clientize(install)
    end
  end

  def token_expired?(%{token: nil, token_expires_at: _e}), do: true
  def token_expired?(%{token: _t, token_expires_at: nil}), do: true

  def token_expired?(%{token_expires_at: expires}) do
    Mrgr.DateMath.in_the_past?(expires)
  end

  def refresh_token!(%Installation{} = install) do
    at = request_new_token(install)

    Mrgr.Installation.set_tokens(install, at)
  end

  def request_new_token(%{external_id: id} = _installation) do
    token = Mrgr.Github.JwtToken.signed_jwt()

    client = Tentacat.Client.new(%{jwt: token})
    response = Tentacat.App.Installations.token(client, id)
    Mrgr.Github.parse_into(response, Mrgr.Github.AccessToken)
  end

  # assumes token is fresh!
  def clientize(%Installation{token: token}) do
    Tentacat.Client.new(%{access_token: token})
  end
end
