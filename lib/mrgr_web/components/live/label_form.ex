defmodule MrgrWeb.Components.Live.LabelForm do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    selected_ids = assigns.selected_repository_ids || []

    socket
    |> assign(assigns)
    |> assign(:selected_repository_ids, MapSet.new(selected_ids))
    |> assign(:changeset, build_changeset(assigns.object))
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
    changeset =
      socket.assigns.object
      |> build_changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("save", %{"label" => params}, socket) do
    object = socket.assigns.object

    params =
      params
      |> Map.put(
        "label_repositories",
        Enum.map(socket.assigns.selected_repository_ids, fn id -> %{"repository_id" => id} end)
      )

    res =
      case creating?(object) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation_id)
          |> Mrgr.Label.create_from_form()

        false ->
          Mrgr.Label.update(object, params)
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
    Mrgr.Label.delete(label)

    socket
    |> hide_detail()
    |> noreply()
  end

  defp build_changeset(schema, params \\ %{}) do
    Mrgr.Schema.Label.changeset(schema, params)
  end

  defp creating?(%{id: nil}), do: true
  defp creating?(_), do: false

  defp editing?(obj), do: !creating?(obj)

  defp all_repos_selected?(all, selected) do
    Enum.count(all) == Enum.count(selected)
  end
end
