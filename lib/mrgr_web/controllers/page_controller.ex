defmodule MrgrWeb.PageController do
  use MrgrWeb, :controller

  plug :redirect_signed_in_user

  def index(conn, _params) do
    render(conn, "index.html")
  end

  defp redirect_signed_in_user(conn, opts) do
    conn = MrgrWeb.Plug.Auth.authenticate_user(conn, opts)

    case MrgrWeb.Plug.Auth.signed_in?(conn) do
      true ->
        redirect(conn, to: Routes.pending_merge_path(conn, :index))

      false ->
        conn
    end
  end
end
