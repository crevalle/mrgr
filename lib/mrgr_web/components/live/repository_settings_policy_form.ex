defmodule MrgrWeb.Components.Live.RepositorySettingsPolicyForm do
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
  def handle_event("validate", %{"repository_settings_policy" => params}, socket) do
    changeset =
      socket.assigns.object
      |> build_changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> assign(:changeset, changeset)
    |> noreply()
  end

  def handle_event("save", %{"repository_settings_policy" => params}, socket) do
    object = socket.assigns.object

    params =
      Map.put(params, "repository_ids", MapSet.to_list(socket.assigns.selected_repository_ids))

    res =
      case creating?(object) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation.id)
          |> Mrgr.RepositorySettingsPolicy.create()

        false ->
          Mrgr.RepositorySettingsPolicy.update(object, params)
      end

    case res do
      {:ok, _policy} ->
        socket
        |> hide_detail()
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete-policy", _params, socket) do
    policy = socket.assigns.object
    Mrgr.RepositorySettingsPolicy.delete(policy)

    socket
    |> hide_detail()
    |> noreply()
  end

  defp build_changeset(schema, params \\ %{}) do
    Mrgr.Schema.RepositorySettingsPolicy.changeset(schema, params)
  end

  defp creating?(%{id: nil}), do: true
  defp creating?(_), do: false

  defp editing?(obj), do: !creating?(obj)

  defp all_repos_selected?(all, selected) do
    Enum.count(all) == Enum.count(selected)
  end
end
