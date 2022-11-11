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

      policies = Mrgr.RepositorySettingsPolicy.for_installation(current_user.current_installation)

      repo_counts = Mrgr.Repository.id_counts_for_policies(Enum.map(policies, & &1.id))

      socket
      |> assign(:repos, repos)
      |> assign(:repo_counts, repo_counts)
      |> assign(:form_subject, nil)
      |> assign(:policies, policies)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-form", _params, socket) do
    socket
    |> assign(:form_subject, %Mrgr.Schema.RepositorySettingsPolicy{})
    |> noreply()
  end

  def handle_event("edit-policy", %{"id" => id}, socket) do
    policy =
      socket.assigns.policies
      |> Mrgr.List.find(id)

    socket
    |> assign(:form_subject, policy)
    |> noreply()
  end

  def handle_event("apply-policy", %{"policy_id" => policy_id, "repo_id" => repo_id}, socket) do
    policy = Mrgr.List.find(socket.assigns.policies, policy_id)
    repository = Mrgr.List.find(socket.assigns.repos, repo_id)

    %{policy_id: policy.id, repo_id: repository.id}
    |> Mrgr.Worker.RepoSettingsSync.new()
    |> Oban.insert()

    socket
    |> start_apply_policy_spinner(repo_id)
    |> noreply()
  end

  def handle_event("apply-policy-to-all", %{"policy_id" => policy_id}, socket) do
    policy = Mrgr.List.find(socket.assigns.policies, policy_id)
    repo_ids = Map.get(socket.assigns.repo_counts, policy_id)

    %{policy_id: policy.id}
    |> Mrgr.Worker.RepoSettingsSync.new()
    |> Oban.insert()

    Enum.reduce(repo_ids, socket, fn repo_id, s ->
      start_apply_policy_spinner(s, repo_id)
    end)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_created, payload: policy}, socket) do
    policies = [policy | socket.assigns.policies]
    policies = Enum.sort_by(policies, & &1.name)

    repo_counts = Mrgr.Repository.id_counts_for_policies(Enum.map(policies, & &1.id))

    socket
    |> Flash.put(:info, "Policy #{policy.name} was added.")
    |> assign(:policies, policies)
    |> assign(:repo_counts, repo_counts)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_updated, payload: policy}, socket) do
    policies = Mrgr.List.replace(socket.assigns.policies, policy)

    # this will run a bunch of times when apply_to_new_repo is triggered,
    # since we publish several _updated messages for each other policy.
    # don't worry about it for now, there won't be a lot of policies
    policy_ids = Enum.map(policies, & &1.id)
    repo_counts = Mrgr.Repository.id_counts_for_policies(policy_ids)

    socket
    |> Flash.put(:info, "Policy #{policy.name} was updated.")
    |> assign(:policies, policies)
    |> assign(:repo_counts, repo_counts)
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
    repos = Mrgr.List.replace(socket.assigns.repos, repository)

    socket
    |> stop_apply_policy_spinner(repository.id)
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def start_apply_policy_spinner(socket, repo_id) do
    socket
    |> push_event("js-exec", %{to: "#apply-policy-#{repo_id}", attr: "data-hide"})
    |> push_event("js-exec", %{to: "#spinner-#{repo_id}", attr: "data-spinning"})
  end

  def stop_apply_policy_spinner(socket, repo_id) do
    socket
    |> push_event("js-exec", %{to: "#spinner-#{repo_id}", attr: "data-done"})
    |> push_event("js-exec", %{to: "#apply-policy-#{repo_id}", attr: "data-show"})
  end

  def repo_count(counts, %{id: id}) do
    counts
    |> Map.get(id)
    |> Enum.count()
  end
end
