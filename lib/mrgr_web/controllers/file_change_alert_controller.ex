defmodule MrgrWeb.FileChangeAlertController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    render(conn)
  end

  def edit(conn, %{"id" => name}) do
    render(conn, repo_name: name)
  end
end

