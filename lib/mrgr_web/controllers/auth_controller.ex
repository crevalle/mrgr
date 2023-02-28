defmodule MrgrWeb.AuthController do
  use MrgrWeb, :controller

  require Logger

  def new(conn, _params) do
    conn
    |> assign(:page_title, "Sign In")
    |> render()
  end

  def sign_up(conn, _params) do
    conn
    |> assign(:page_title, "Sign Up")
    |> render()
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
        case Mrgr.User.find_or_create_from_github(data, token) do
          {:ok, user} ->
            conn
            |> sign_in(user)
            |> put_flash(:info, "Welcome Back! 👋")
            |> redirect(to: post_sign_in_path(conn, user))

          {:error, _changeset} ->
            Logger.warn("OAuth error: [DATA] #{inspect(data)} \r [TOKEN] #{inspect(token)}")

            conn
            |> put_flash(
              :info,
              "Sorry, we couldn't parse your Github data.  Is your email set up?"
            )
            |> redirect(to: Routes.auth_path(conn, :new))
        end

      {:error, %OAuth2.Response{body: body}} ->
        Logger.warn("OAuth error: #{inspect(body)}")

        conn
        |> put_flash(:info, "Sorry, OAuth expired.  Please log in again.")
        |> redirect(to: Routes.auth_path(conn, :new))

      {:error, %OAuth2.Error{reason: reason}} ->
        Logger.warn("OAuth error: #{inspect(reason)}")

        conn
        |> put_flash(:info, "Sorry, OAuth failed.  Please try again later.")
        |> redirect(to: Routes.auth_path(conn, :new))
    end
  end

  # will change when members whom we know about sign up.
  def post_sign_in_path(conn, %{current_installation_id: nil}) do
    Routes.onboarding_path(conn, :index)
  end

  def post_sign_in_path(conn, _user) do
    Routes.pull_request_path(conn, :index)
  end
end
