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
    user =
      auth
      |> generate_params()
      |> Mrgr.User.find_or_create()

    conn
    |> sign_in(user)
    |> put_flash(:info, "Signed in!")
    |> redirect(to: "/")
  end

  defp generate_params(%{credentials: credentials, info: info} = _auth) do
    tokens = %{
      token: credentials.token,
      refresh_token: credentials.refresh_token,
      # utc
      token_expires_at: DateTime.from_unix!(credentials.expires_at)
    }

    info
    |> Map.from_struct()
    |> Map.merge(tokens)
    |> Map.put(:provider, "github")
  end
end
