defmodule MrgrWeb.Plug.Auth do
  import Plug.Conn

  def on_mount(:default, _session, params, socket) do
    case MrgrWeb.Plug.Auth.find_user(params["user_id"]) do
      %Mrgr.Schema.User{} = user ->
        {:cont, Phoenix.LiveView.assign(socket, :current_user, user)}

      _nope ->
        {:halt, socket}
    end
  end

  @spec sign_in(Plug.Conn.t(), Mrgr.Schema.User.t()) :: Plug.Conn.t()
  def sign_in(conn, %{id: id}) do
    put_session(conn, :user_id, id)
  end

  @spec signed_in?(Plug.Conn.t()) :: boolean()
  def signed_in?(%{assigns: %{current_user: user}}) when not is_nil(user), do: true
  def signed_in?(_), do: false

  @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
  def sign_out(conn) do
    configure_session(conn, drop: true)
  end

  @spec fetch_user(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def fetch_user(conn, _opts) do
    with user_id when not is_nil(user_id) <- get_session(conn, :user_id),
         %Mrgr.Schema.User{} = user <- find_user(user_id) do
      assign(conn, :current_user, user)
    else
      _bogus ->
        conn
    end
  end

  @spec require_user(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def require_user(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> redirect_unsigned_in_user()
        |> halt()

      %{current_installation_id: nil} ->
        conn
        |> redirect_connect_github()
        |> halt()

      _user ->
        conn
    end
  end

  # assumes a current_user, ie, someone is signed in
  def require_admin(conn, _opts) do
    case admin?(conn.assigns.current_user) do
      true ->
        conn

      _ ->
        conn
        |> redirect_non_admin_user()
        |> halt()
    end
  end

  def admin?(%{nickname: "desmondmonster"}), do: true
  def admin?(_), do: false

  @spec find_user(integer) :: Mrgr.Schema.User.t() | nil
  def find_user(id) do
    Mrgr.User.find_with_current_installation(id)
  end

  @spec redirect_to_original_url_or(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def redirect_to_original_url_or(conn, new_path) do
    case get_session(conn, :headed_to) do
      nil ->
        Phoenix.Controller.redirect(conn, to: new_path)

      original_path ->
        conn
        |> put_session(:headed_to, nil)
        |> Phoenix.Controller.redirect(to: original_path)
    end
  end

  defp redirect_non_admin_user(conn) do
    conn
    |> put_session(:headed_to, conn.request_path)
    |> Phoenix.Controller.put_flash(:info, "What do you think you're doing?")
    |> Phoenix.Controller.redirect(to: "/")
  end

  defp redirect_unsigned_in_user(conn) do
    conn
    |> put_session(:headed_to, conn.request_path)
    |> Phoenix.Controller.put_flash(:info, "Please sign in to check that out!")
    |> Phoenix.Controller.redirect(to: "/")
  end

  defp redirect_connect_github(conn) do
    conn
    |> put_session(:headed_to, conn.request_path)
    |> Phoenix.Controller.put_flash(:info, "Please connect Github to continue")
    |> Phoenix.Controller.redirect(to: "/")
  end
end
