defmodule MrgrWeb.OnboardingController do
  use MrgrWeb, :controller

  def index(conn, _params) do
    render(conn)
  end

  def installation_complete(conn, _params) do
    render(conn)
  end
end
