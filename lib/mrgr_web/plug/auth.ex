defmodule MrgrWeb.Plug.Auth do
  import Plug.Conn

  def on_mount(:default, _session, params, socket) do
    socket =
      Phoenix.Component.assign_new(socket, :current_user, fn ->
        look_for_user(params["user_id"])
      end)

    case socket.assigns.current_user do
      %Mrgr.Schema.User{} = _user ->
        {:cont, socket}

      nil ->
        {:halt, socket}
    end
  end

  def on_mount(:admin, _session, params, socket) do
    socket =
      Phoenix.Component.assign_new(socket, :current_user, fn ->
        look_for_user(params["user_id"])
      end)

    case admin?(socket.assigns.current_user) do
      true ->
        {:cont, socket}

      false ->
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

  @spec authenticate_user(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def authenticate_user(conn, _opts) do
    with user_id when not is_nil(user_id) <- get_session(conn, :user_id),
         %Mrgr.Schema.User{} = user <- look_for_user(user_id) do
      assign(conn, :current_user, user)
    else
      _bogus ->
        conn
    end
  end

  @spec require_user(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def require_user(conn, _opts) do
    case signed_in?(conn) do
      true ->
        conn

      false ->
        conn
        |> redirect_unsigned_in_user()
        |> halt()
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

  @spec look_for_user(integer) :: Mrgr.Schema.User.t() | nil
  def look_for_user(id) do
    with %Mrgr.Schema.User{} = user <- Mrgr.User.find_with_current_installation(id) do
      record_seen!(user)
    end
  end

  def record_seen!(user) do
    user
    |> Mrgr.Schema.User.seen_changeset()
    |> Mrgr.Repo.update!()
  end

  def redirect_logged_in_to_dashboard(conn, _opts) do
    case signed_in?(conn) do
      true ->
        conn
        |> Phoenix.Controller.put_flash(:info, "Hello again.")
        |> Phoenix.Controller.redirect(to: "/pull-requests")
        |> halt()

      false ->
        conn
    end
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
    |> Phoenix.Controller.redirect(to: "/sign-in")
  end
end
