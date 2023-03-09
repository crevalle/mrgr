defmodule MrgrWeb.Live.Checklist do
  use MrgrWeb, :live_view

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      templates = Mrgr.ChecklistTemplate.for_installation(current_user.current_installation)

      socket
      |> put_title("File Change Alerts")
      |> assign(:templates, templates)
      |> assign(:new_template, nil)
      |> assign(:changeset, nil)
      |> assign(:detail, nil)
      |> assign(:repository_list, [])
      |> assign(:selected_repository_ids, MapSet.new())
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("show-detail", %{"id" => id}, socket) do
    template = Mrgr.List.find(socket.assigns.templates, id)

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

    # Enum.map(@user.roles, &(&1.id)
    repo_list =
      socket.assigns.current_user
      |> Mrgr.Repository.for_user_with_hif_rules()

    socket
    |> assign(:detail, nil)
    |> assign(:new_template, new_template)
    |> assign(:changeset, cs)
    |> assign(:repository_list, repo_list)
    |> noreply()
  end

  def handle_event("toggle-selected-repository", %{"repo-id" => id}, socket) do
    selected = socket.assigns.selected_repository_ids
    id = String.to_integer(id)

    selected =
      case MapSet.member?(selected, id) do
        true -> MapSet.delete(selected, id)
        false -> MapSet.put(selected, id)
      end

    socket
    |> assign(:selected_repository_ids, selected)
    |> noreply()
  end

  def handle_event("toggle-all-repositories", _params, socket) do
    selected = socket.assigns.selected_repository_ids
    all_repos = socket.assigns.repository_list

    selected =
      case all_repos_selected?(all_repos, selected) do
        true -> MapSet.new()
        false -> MapSet.new(Enum.map(all_repos, & &1.id))
      end

    socket
    |> assign(:selected_repository_ids, selected)
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

  def handle_event("add-check-template", _params, socket) do
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
      |> Map.put("repository_ids", MapSet.to_list(socket.assigns.selected_repository_ids))

    case Mrgr.ChecklistTemplate.create(params) do
      {:ok, template} ->
        templates = socket.assigns.templates

        socket
        |> assign(:templates, [template] ++ templates)
        |> assign(:changeset, nil)
        |> assign(:new_template, nil)
        |> Flash.put(:info, "Checklist created!")
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    templates = socket.assigns.templates

    marked = Mrgr.List.find(templates, id)
    updated_list = Mrgr.List.remove(templates, id)

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

  defp all_repos_selected?(all, selected) do
    Enum.count(all) == Enum.count(selected)
  end
end
