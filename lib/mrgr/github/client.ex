defmodule Mrgr.Github.Client do
  alias Mrgr.Schema.{Installation, User}

  @spec new(Installation.t() | User.t() | integer()) :: Tentacat.Client.t()
  def new(actor) do
    actor = fetch_token(actor)

    actor
    |> token_expired?()
    |> case do
      true ->
        actor
        |> refresh_token!()
        |> clientize()

      false ->
        clientize(actor)
    end
  end

  def graphql(installation) do
    %Tentacat.Client{auth: %{access_token: token}} = new(installation)

    token
  end

  def graphql_token(client) do
    client.auth.access_token
  end

  def fetch_token(%{installation_id: id}) when is_integer(id) do
    fetch_token(id)
  end

  def fetch_token(id) when is_integer(id) do
    Mrgr.Repo.get(Mrgr.Schema.Installation, id)
  end

  def fetch_token(actor) do
    # reload the thing to make sure we have the latest tokenry.
    # when performing multiple requests on, say, a list of merges, they
    # pass in their one copy of the installation that was set at the beginning.
    # a refreshed installation is not used, so we think its token has expired prematurely
    # and we refresh it with each request :/.
    #
    # in future we'll look up the token itself but i don't want to build
    # that out as a separate concern right now for time's sake.  reloading
    # the actor will "fetch the latest token"
    Mrgr.Repo.get(actor.__struct__, actor.id)
  end

  # new installation.  users should get a token immediately upon creation
  def token_expired?(%{token: nil}), do: true
  # user tokens don't expire, ie, have a token_expires_at.  But we expect there to be a token.
  def token_expired?(%User{token_expires_at: nil, token: token}) when is_bitstring(token),
    do: false

  def token_expired?(%Installation{token_expires_at: nil}), do: true

  def token_expired?(%{token_expires_at: expires}) do
    Mrgr.DateTime.in_the_past?(expires)
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

  def request_new_token(%Installation{} = installation) do
    Mrgr.Github.API.get_new_installation_token(installation)
  end

  # assumes token is fresh!
  def clientize(%{token: token}) do
    Tentacat.Client.new(%{access_token: token})
  end
end
