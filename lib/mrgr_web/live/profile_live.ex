defmodule MrgrWeb.ProfileLive do
  use MrgrWeb, :live_view

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      socket
      |> put_title("Your Profile")
      |> assign(:changeset, nil)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("edit", _params, socket) do
    socket
    |> assign(:changeset, build_changeset(socket.assigns.current_user))
    |> noreply()
  end

  def handle_event("save", %{"user" => params}, socket) do
    socket.assigns.current_user
    |> build_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:error, cs} ->
        socket
        |> assign(:changeset, cs)
        |> noreply()

      {:ok, user} ->
        socket
        |> Flash.put(:info, "Updated!")
        |> assign(:current_user, user)
        |> assign(:changeset, nil)
        |> noreply()
    end
  end

  def handle_event("update-weekly-changelog-preference", %{"user" => params}, socket) do
    socket.assigns.current_user
    |> Mrgr.Schema.User.weekly_changelog_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, user} ->
        socket
        |> Flash.put(:info, "Updated!")
        |> assign(:current_user, user)
        |> noreply()

      {:error, _cs} ->
        socket
        |> Flash.put(:error, "Couldn't perform update : /")
        |> noreply()
    end
  end

  def build_changeset(user, params \\ %{}) do
    user
    |> Mrgr.Schema.User.notification_changeset(params)
  end
end
