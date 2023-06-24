defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      Mrgr.PubSub.subscribe_to_installation(current_user)

      repos = Mrgr.Repository.for_user(current_user)
      visible_repo_ids = fetch_visible_repo_ids(current_user)

      socket
      |> assign(:all_repos, repos)
      |> assign(:repo_list, repos)
      |> assign(:visible_repo_ids, visible_repo_ids)
      |> assign(:installation, current_user.current_installation)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_info(%{event: @repository_updated, payload: repository}, socket) do
    all_repos = Mrgr.List.replace(socket.assigns.all_repos, repository)
    repo_list = Mrgr.List.replace(socket.assigns.repo_list, repository)

    socket
    |> Flash.put(:info, "#{repository.name} was updated.")
    |> assign(:all_repos, all_repos)
    |> assign(:repo_list, repo_list)
    |> noreply()
  end

  def handle_info(%{event: @repository_merge_freeze_status_changed, payload: repository}, socket) do
    all_repos = Mrgr.List.replace(socket.assigns.all_repos, repository)

    what_happened =
      case repository.merge_freeze_enabled do
        true -> "enabled"
        false -> "lifted"
      end

    socket
    |> Flash.put(:info, "Merge freeze #{what_happened}!")
    |> assign(:all_repos, all_repos)
    |> noreply()
  end

  def handle_info(%{event: @installation_repositories_synced, payload: installation}, socket) do
    socket
    |> assign(:installation, installation)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def repo_count(counts, %{id: id}) do
    counts
    |> Map.get(id)
    |> Enum.count()
  end

  def fetch_visible_repo_ids(user) do
    user
    |> Mrgr.User.visible_repos_at_current_installation()
    |> Mrgr.Repo.all()
    |> Enum.map(& &1.repository_id)
  end

  def repo_visible_to_user?(repo, visible_repo_ids) do
    Enum.member?(visible_repo_ids, repo.id)
  end
end
