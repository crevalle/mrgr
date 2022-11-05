defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      repos = Mrgr.Repository.for_user_with_rules(current_user)

      profiles =
        Mrgr.RepositorySecurityProfile.for_installation(current_user.current_installation)

      socket
      |> assign(:repos, repos)
      |> assign(:form, nil)
      |> assign(:profiles, profiles)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-form", _params, socket) do
    changeset = build_changeset()
    form = Form.create(changeset)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("close-form", _params, socket) do
    socket
    |> assign(:form, nil)
    |> noreply()
  end

  def handle_event("save", %{"repository_security_profile" => params}, socket) do
    form = socket.assigns.form

    res =
      case Form.creating?(form) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation.id)
          |> Mrgr.RepositorySecurityProfile.create()

        false ->
          Mrgr.RepositorySecurityProfile.update(Form.object(form), params)
      end

    case res do
      {:ok, profile} ->
        socket
        |> assign(:form, nil)
        |> Flash.put(:info, "Profile Saved!")
        |> noreply()

      {:error, changeset} ->
        form = Form.update_changeset(form, changeset)

        socket
        |> assign(:form, form)
        |> noreply()
    end
  end

  def handle_event("delete-profile", _params, socket) do
    profile = Form.object(socket.assigns.form)
    Mrgr.Repo.delete(profile)

    socket
    |> assign(:form, nil)
    |> Flash.put(:info, "Profile Deleted 🗑")
    |> noreply()
  end

  def handle_event("edit-profile", %{"id" => id}, socket) do
    profile = Mrgr.List.find(socket.assigns.profiles, id)
    form = Form.edit(build_changeset(profile))

    socket
    |> assign(:form, form)
    |> noreply()
  end

  defp build_changeset(schema \\ %Mrgr.Schema.RepositorySecurityProfile{}) do
    Mrgr.Schema.RepositorySecurityProfile.changeset(schema)
  end
end
