defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      repos = Mrgr.Repository.for_user_with_rules(current_user)

      socket
      |> assign(:repos, repos)
      |> assign(:form, nil)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-form", _params, socket) do
    changeset = build_changeset() |> IO.inspect()
    form = %{action: :create, changeset: changeset}

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("close-form", _params, socket) do
    socket
    |> assign(:form, nil)
    |> noreply()
  end

  def handle_event("save", params, socket) do
    IO.inspect(params)

    socket
    |> assign(:form, nil)
    |> Flash.put(:info, "Policy Saved!")
    |> noreply()
  end

  defp build_changeset do
    %Mrgr.Schema.RepositorySecurityProfile{}
    |> Mrgr.Schema.RepositorySecurityProfile.changeset()
  end
end
