defmodule MrgrWeb.PendingMergeController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    IO.inspect(conn.assigns.current_user)
    merges = Mrgr.Merge.pending_merges(conn.assigns.current_user)

    render(conn, "index.html", merges: merges)
  end
end
