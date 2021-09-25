defmodule MrgrWeb.Auth do
  import Plug.Conn

  @spec sign_in(Plug.Conn.t(), %{atom() => integer()}) :: Plug.Conn.t()
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

  @spec fetch_user(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def require_user(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> redirect_unsigned_in_user()
        |> halt()

      _user ->
        conn
    end
  end

  @spec find_user(integer) :: Mrgr.Schema.User.t() | nil
  def find_user(id) do
    Mrgr.User.find(id)
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

  defp redirect_unsigned_in_user(conn) do
    conn
    |> put_session(:headed_to, conn.request_path)
    |> Phoenix.Controller.put_flash(:info, "Please sign in to check that out!")
    |> Phoenix.Controller.redirect(to: "/")
  end
end
