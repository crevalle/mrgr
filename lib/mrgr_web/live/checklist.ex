defmodule MrgrWeb.Live.Checklist do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      templates = Mrgr.ChecklistTemplate.for_installation(current_user.current_installation)

      socket
      |> assign(:current_user, current_user)
      |> assign(:templates, templates)
      |> assign(:changeset, nil)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-add-form", _params, socket) do
    cs = Mrgr.Schema.ChecklistTemplate.create_changeset()

    socket
    |> assign(:changeset, cs)
    |> noreply()
  end

  def handle_event("save", %{"checklist_template" => params}, socket) do
    params
    |> Map.put("installation_id", socket.assigns.current_user.current_installation_id)
    |> Map.put("creator_id", socket.assigns.current_user.id)
    |> Mrgr.Schema.ChecklistTemplate.create_changeset()
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, template} ->
        templates = socket.assigns.templates

        socket
        |> assign(:templates, [template] ++ templates)
        |> assign(:changeset, nil)
        |> put_flash(:info, "Checklist created!")
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("cancel", _params, socket) do
    socket
    |> assign(:changeset, nil)
    |> noreply()
  end
end
