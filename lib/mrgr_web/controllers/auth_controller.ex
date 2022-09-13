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
    %{token: token} =
      client =
      Auth.GitHub.get_token!(code: code)
      |> IO.inspect(label: "CLIENT")

    # Request the user's data with the access token
    case OAuth2.Client.get(client, "/user") do
      {:ok, %OAuth2.Response{body: data}} ->
        IO.inspect(data, label: "*** GITHUB DATA")

        user = Mrgr.User.find_or_create_from_github(data, token)

        conn
        |> sign_in(user)
        |> put_flash(:info, "Hi there! 👋")
        |> redirect(to: Routes.pending_merge_path(conn, :index))

      {:error, %OAuth2.Response{body: body}} ->
        IO.inspect("OAuth Error: code #{code} #{inspect(body)}")

        conn
        |> put_flash(:info, "Sorry, OAuth expired.  Please log in again.")
        |> redirect(to: "/")

      {:error, %OAuth2.Error{reason: reason}} ->
        IO.inspect("OAuth Error: code #{code} #{inspect(reason)}")

        conn
        |> put_flash(:info, "Sorry, OAuth expired.  Please log in again.")
        |> redirect(to: "/")
    end
  end
end
