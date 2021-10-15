defmodule MrgrWeb.RepositoryController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    repos = Mrgr.User.repos(conn.assigns.current_user)

    render(conn, "index.html", repos: repos)
  end
end
