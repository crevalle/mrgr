defmodule MrgrWeb.Live.Checklist do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      templates = Mrgr.ChecklistTemplate.for_installation(current_user.current_installation)

      socket
      |> assign(:current_user, current_user)
      |> assign(:templates, templates)
      |> assign(:new_template, nil)
      |> assign(:changeset, nil)
      |> assign(:detail, nil)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("show-detail", %{"id" => id}, socket) do
    template = Mrgr.Utils.find_item_in_list(socket.assigns.templates, id)

    socket
    |> assign(:detail, template)
    |> assign(:changeset, nil)
    |> noreply()
  end

  def handle_event("open-add-form", _params, socket) do
    new_template = %Mrgr.Schema.ChecklistTemplate{
      check_templates: [%Mrgr.Schema.CheckTemplate{}]
    }

    cs = Mrgr.Schema.ChecklistTemplate.create_changeset(new_template)

    socket
    |> assign(:detail, nil)
    |> assign(:new_template, new_template)
    |> assign(:changeset, cs)
    |> noreply()
  end

  def handle_event("validate", %{"checklist_template" => params}, socket) do
    changeset =
      socket.assigns.new_template
      |> Mrgr.Schema.ChecklistTemplate.create_changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("add-check-template", params, socket) do
    existing_check_templates =
      Map.get(
        socket.assigns.changeset.changes,
        :check_templates,
        socket.assigns.new_template.check_templates
      )

    check_templates =
      existing_check_templates
      |> Enum.concat([
        Mrgr.Schema.CheckTemplate.changeset(%Mrgr.Schema.CheckTemplate{temp_id: gen_temp_id()})
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:check_templates, check_templates)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("remove-check-template", %{"remove" => temp_id}, socket) do
    check_templates =
      socket.assigns.changeset.changes.check_templates
      |> Enum.reject(fn %{data: check_template} ->
        check_template.temp_id == temp_id
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_embed(:check_templates, check_templates)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("save", %{"checklist_template" => params}, socket) do
    params =
      params
      |> Map.put("installation", socket.assigns.current_user.current_installation)
      |> Map.put("creator", socket.assigns.current_user)

    %Mrgr.Schema.ChecklistTemplate{}
    |> Mrgr.Schema.ChecklistTemplate.create_changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, template} ->
        templates = socket.assigns.templates

        socket
        |> assign(:templates, [template] ++ templates)
        |> assign(:changeset, nil)
        |> assign(:new_template, nil)
        |> put_flash(:info, "Checklist created!")
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    templates = socket.assigns.templates

    marked = Mrgr.Utils.find_item_in_list(templates, id)
    updated_list = Mrgr.Utils.remove_item_from_list(templates, id)

    {:ok, _obj} = Mrgr.Repo.delete(marked)

    socket
    |> assign(:detail, nil)
    |> assign(:templates, updated_list)
    |> noreply()
  end

  def handle_event("close-detail", _params, socket) do
    socket
    |> assign(:changeset, nil)
    |> assign(:detail, nil)
    |> noreply()
  end

  defp gen_temp_id do
    Ecto.UUID.generate()
  end
end
