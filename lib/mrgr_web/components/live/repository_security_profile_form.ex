defmodule MrgrWeb.Components.Live.RepositorySecurityProfileForm do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(:selected_repository_ids, MapSet.new(assigns.selected_repository_ids))
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

  def handle_event("save", %{"repository_security_profile" => params}, socket) do
    object = socket.assigns.object

    params =
      Map.put(params, "repository_ids", MapSet.to_list(socket.assigns.selected_repository_ids))

    res =
      case creating?(object) do
        true ->
          params
          |> Map.put("installation_id", socket.assigns.current_user.current_installation.id)
          |> Mrgr.RepositorySecurityProfile.create()

        false ->
          Mrgr.RepositorySecurityProfile.update(object, params)
      end

    case res do
      {:ok, _profile} ->
        close_me()

        socket
        |> noreply()

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  def handle_event("delete-profile", _params, socket) do
    profile = socket.assigns.object
    Mrgr.RepositorySecurityProfile.delete(profile)

    close_me()

    socket
    |> noreply()
  end

  def handle_event("close-form", _params, socket) do
    close_me()

    noreply(socket)
  end

  defp close_me do
    send(self(), :close_form)
  end

  defp build_changeset(schema \\ %Mrgr.Schema.RepositorySecurityProfile{}) do
    Mrgr.Schema.RepositorySecurityProfile.changeset(schema)
  end

  defp creating?(%{id: nil}), do: true
  defp creating?(_), do: false

  defp editing?(obj), do: !creating?(obj)

  defp all_repos_selected?(all, selected) do
    Enum.count(all) == Enum.count(selected)
  end
end
