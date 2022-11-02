defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      repos = Mrgr.Repository.for_user_with_rules(current_user)

      socket
      |> assign(:repos, repos)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end
end
