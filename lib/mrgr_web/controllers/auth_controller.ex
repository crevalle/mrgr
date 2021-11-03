defmodule MrgrWeb.AuthController do
  use MrgrWeb, :controller

  plug Ueberauth

  def delete(conn, _params) do
    conn
    |> sign_out()
    |> put_flash(:info, "Signed out! Thanks!")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    IO.inspect(auth, label: "*** OAUTH CALLBACK")
    user = Mrgr.User.find_or_create_from_github(auth)

    conn
    |> sign_in(user)
    |> put_flash(:info, "Signed in!")
    |> redirect(to: "/")
  end
end
