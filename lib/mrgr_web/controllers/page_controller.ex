defmodule MrgrWeb.PageController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
