defmodule MrgrWeb.AuthController do
  use MrgrWeb, :controller

  def new(conn, _params) do
    render(conn)
  end

  def delete(conn, _params) do
    conn
    |> sign_out()
    |> put_flash(:info, "Signed out! Thanks!")
    |> redirect(to: "/")
  end

  def github(conn, _params) do
    redirect(conn, external: Auth.GitHub.authorize_url!())
  end

  # user sign in
  def callback(conn, %{"code" => code}) do
    # Exchange an auth code for an access token
    %{token: token} = client = Auth.GitHub.get_token!(code: code)

    # Request the user's data with the access token
    case OAuth2.Client.get(client, "/user") do
      {:ok, %OAuth2.Response{body: data}} ->
        user = Mrgr.User.find_or_create_from_github(data, token)

        conn
        |> sign_in(user)
        |> put_flash(:info, "Hi there! 👋")
        |> redirect(to: post_sign_in_path(conn, user))

      {:error, %OAuth2.Response{body: _body}} ->
        conn
        |> put_flash(:info, "Sorry, OAuth expired.  Please log in again.")
        |> redirect(to: Routes.auth_path(conn, :github))

      {:error, %OAuth2.Error{reason: _reason}} ->
        conn
        |> put_flash(:info, "Sorry, OAuth expired.  Please log in again.")
        |> redirect(to: Routes.auth_path(conn, :github))
    end
  end

  # will change when members whom we know about sign up.
  def post_sign_in_path(conn, %{current_installation_id: nil}) do
    Routes.onboarding_path(conn, :index)
  end

  def post_sign_in_path(conn, _user) do
    Routes.pending_merge_path(conn, :index)
  end
end
