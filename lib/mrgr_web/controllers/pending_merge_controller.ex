defmodule MrgrWeb.PendingMergeController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
