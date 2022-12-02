defmodule MrgrWeb.Components.Live.LabelForm do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    selected_ids = assigns.selected_repository_ids || []

    socket
    |> assign(assigns)
    |> assign(:selected_repository_ids, MapSet.new(selected_ids))
    |> assign(:form, build_form(assigns.object))
    |> ok()
  end

  def handle_event("toggle-all-repositories", _params, socket) do
    selected = socket.assigns.selected_repository_ids
    all_repos = socket.assigns.repos

    selected =
      case all_repos_selected?(all_repos, selected) do
        true -> MapSet.new()
        false -> MapSet.new(Enum.map(all_repos, & &1.id))
      end

    socket
    |> assign(:selected_repository_ids, selected)
    |> noreply()
  end

  def handle_event("toggle-selected-repository", %{"id" => id}, socket) do
    selected = socket.assigns.selected_repository_ids

    selected =
      case MapSet.member?(selected, id) do
        true -> MapSet.delete(selected, id)
        false -> MapSet.put(selected, id)
      end

    socket
    |> assign(:selected_repository_ids, selected)
    |> noreply()
  end

  # if I don't save the params here they get wiped when i toggle the repos.
  # not sure why
  def handle_event("validate", %{"label" => params}, socket) do
    # used to trigger updates to label preview
    form = socket.assigns.form

    badge_preview = %{
      color: params["color"],
      name: params["name"]
    }

    # i'm only interested in the badge preview, but i need to set changeset
    # data here otherwise an unknown bug will clear out my fields.  same with FCAs
    form = %{
      form
      | badge_preview: badge_preview,
        changeset: Mrgr.Schema.Label.changeset(form.changeset.data, params)
    }

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("save", %{"label" => params}, socket) do
    object = socket.assigns.object

    label_repository_ids =
      Enum.map(socket.assigns.selected_repository_ids, fn id -> %{"repository_id" => id} end)

    params =
      params
      |> Map.put("label_repositories", label_repository_ids)

    res =
      case creating?(object) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation_id)
          |> Mrgr.Label.create_from_form()

        false ->
          Mrgr.Label.update_from_form(object, params)
      end

    case res do
      {:ok, _label} ->
        socket
        |> hide_detail()
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete", _params, socket) do
    label = socket.assigns.object
    Mrgr.Label.delete_async(label)

    socket
    |> hide_detail()
    |> noreply()
  end

  defp build_form(schema, params \\ %{}) do
    changeset = Mrgr.Schema.Label.changeset(schema, params)

    %{
      changeset: changeset,
      badge_preview: %{
        color: schema.color,
        name: schema.name
      }
    }
  end

  defp creating?(%{id: nil}), do: true
  defp creating?(_), do: false

  defp editing?(obj), do: !creating?(obj)

  defp all_repos_selected?(all, selected) do
    Enum.count(all) == Enum.count(selected)
  end
end
