defmodule MrgrWeb.Plug.Installation do
  use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router

  def redirect_onboarded_users_to_dashboard(conn, _opts) do
    case Mrgr.Installation.onboarded?(conn.assigns.current_user.current_installation) do
      true ->
        Phoenix.Controller.redirect(conn, to: ~p</pull-requests>)

      false ->
        conn
    end
  end

  def redirect_missing_installation_to_onboarding(conn, _opts) do
    case conn.assigns.current_user.current_installation_id do
      nil ->
        Phoenix.Controller.redirect(conn, to: ~p</onboarding>)

      _id ->
        conn
    end
  end
end
