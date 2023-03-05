defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      Mrgr.PubSub.subscribe_to_installation(current_user)

      repos = Mrgr.Repository.for_user_with_policy(current_user)
      visible_repo_ids = fetch_visible_repo_ids(current_user)

      policies = Mrgr.RepositorySettingsPolicy.for_installation(current_user.current_installation)

      socket
      |> assign(:all_repos, repos)
      |> assign(:repo_list, repos)
      |> assign(:visible_repo_ids, visible_repo_ids)
      |> assign(:form_object, %Mrgr.Schema.RepositorySettingsPolicy{})
      |> assign(:selected_policy, nil)
      |> assign(:policies, policies)
      |> assign(:installation, current_user.current_installation)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("select-policy", %{"policy_id" => id}, socket) do
    policy = Mrgr.List.find(socket.assigns.policies, id)

    # unselect if selected
    {selected, repos_for_policy} =
      if selected?(policy, socket.assigns.selected_policy) do
        {nil, socket.assigns.all_repos}
      else
        {policy, repos_for_policy(socket.assigns.all_repos, policy)}
      end

    socket
    |> assign(:selected_policy, selected)
    |> assign(:repo_list, repos_for_policy)
    |> noreply()
  end

  def handle_event("add-policy", _params, socket) do
    socket
    |> assign(:form_object, %Mrgr.Schema.RepositorySettingsPolicy{})
    |> noreply()
  end

  def handle_event("edit-policy", %{"id" => id}, socket) do
    policy =
      socket.assigns.policies
      |> Mrgr.List.find(id)

    socket
    |> assign(:form_object, policy)
    |> noreply()
  end

  def handle_event("enforce-policy", %{"policy_id" => policy_id, "repo_id" => repo_id}, socket) do
    policy = Mrgr.List.find(socket.assigns.policies, policy_id)
    repository = Mrgr.List.find(socket.assigns.all_repos, repo_id)

    %{policy_id: policy.id, repo_id: repository.id}
    |> Mrgr.Worker.EnforceRepositorySettings.new()
    |> Oban.insert()

    socket
    |> start_enforce_policy_spinner(repo_id)
    |> noreply()
  end

  def handle_event("enforce-policy-to-repos", %{"policy_id" => policy_id}, socket) do
    policy = Mrgr.List.find(socket.assigns.policies, policy_id)

    repo_ids =
      socket.assigns.all_repos
      |> repos_for_policy(policy)
      |> Enum.map(& &1.id)

    %{policy_id: policy.id}
    |> Mrgr.Worker.EnforceRepositorySettings.new()
    |> Oban.insert()

    Enum.reduce(repo_ids, socket, fn repo_id, s ->
      start_enforce_policy_spinner(s, repo_id)
    end)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_created, payload: policy}, socket) do
    policies = [policy | socket.assigns.policies]
    policies = Enum.sort_by(policies, & &1.name)

    socket
    |> Flash.put(:info, "Policy #{policy.name} was added.")
    |> assign(:policies, policies)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_updated, payload: policy}, socket) do
    policies = Mrgr.List.replace(socket.assigns.policies, policy)

    # this will run a bunch of times when enforce_to_new_repo is triggered,
    # since we publish several _updated messages for each other policy.
    # don't worry about it for now, there won't be a lot of policies

    socket
    |> Flash.put(:info, "Policy #{policy.name} was updated.")
    |> assign(:policies, policies)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_deleted, payload: policy}, socket) do
    policies = Mrgr.List.remove(socket.assigns.policies, policy)

    socket
    |> Flash.put(:info, "Policy #{policy.name} was deleted.")
    |> assign(:policies, policies)
    |> noreply()
  end

  def handle_info(%{event: @repository_updated, payload: repository}, socket) do
    all_repos = Mrgr.List.replace(socket.assigns.all_repos, repository)
    repo_list = Mrgr.List.replace(socket.assigns.repo_list, repository)
    policies = replace_repo_in_policy(repository, socket.assigns.policies)

    socket
    |> Flash.put(:info, "#{repository.name} was updated.")
    |> stop_enforce_policy_spinner(repository.id)
    |> assign(:all_repos, all_repos)
    |> assign(:repo_list, repo_list)
    |> assign(:policies, policies)
    |> noreply()
  end

  def handle_info(%{event: @installation_repositories_synced, payload: installation}, socket) do
    socket
    |> assign(:installation, installation)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def start_enforce_policy_spinner(socket, repo_id) do
    socket
    |> push_event("js-exec", %{to: "#enforce-policy-#{repo_id}", attr: "data-hide"})
    |> push_event("js-exec", %{to: "#spinner-#{repo_id}", attr: "data-spinning"})
  end

  def stop_enforce_policy_spinner(socket, repo_id) do
    socket
    |> push_event("js-exec", %{to: "#spinner-#{repo_id}", attr: "data-done"})
    |> push_event("js-exec", %{to: "#enforce-policy-#{repo_id}", attr: "data-show"})
  end

  def repo_count(counts, %{id: id}) do
    counts
    |> Map.get(id)
    |> Enum.count()
  end

  def selected?(%{id: id}, %{id: id}), do: true
  def selected?(_policy, _selected), do: false

  def replace_repo_in_policy(%{repository_settings_policy_id: nil}, policies), do: policies

  def replace_repo_in_policy(repo, policies) do
    # for updating compliant repo counts
    %{repositories: repositories} =
      its_policy = Mrgr.List.find(policies, repo.repository_settings_policy_id)

    updated_policy = %{its_policy | repositories: Mrgr.List.replace(repositories, repo)}

    Mrgr.List.replace(policies, updated_policy)
  end

  # new policy form.  don't select repos with no associated policy
  def repos_for_policy(_repos, %{id: nil}), do: []

  def repos_for_policy(repos, policy) do
    Enum.filter(repos, fn r ->
      r.repository_settings_policy_id == policy.id
    end)
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
