defmodule MrgrWeb.RepositoryListLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Repository

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      Mrgr.PubSub.subscribe_to_installation(current_user)

      repos = Mrgr.Repository.for_user_with_rules(current_user)

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

  def handle_info(:close_form, socket) do
    socket
    |> assign(:form_subject, nil)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_created, payload: policy}, socket) do
    policies = [policy | socket.assigns.policies]
    policies = Enum.sort_by(policies, & &1.title)

    repo_counts = Mrgr.Repository.id_counts_for_policies(Enum.map(policies, & &1.id))

    socket
    |> Flash.put(:info, "Policy #{policy.title} was added.")
    |> assign(:policies, policies)
    |> assign(:repo_counts, repo_counts)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_updated, payload: policy}, socket) do
    policies = Mrgr.List.replace(socket.assigns.policies, policy)

    repo_counts = Mrgr.Repository.id_counts_for_policies(Enum.map(policies, & &1.id))

    socket
    |> Flash.put(:info, "Policy #{policy.title} was updated.")
    |> assign(:policies, policies)
    |> assign(:repo_counts, repo_counts)
    |> noreply()
  end

  def handle_info(%{event: @repository_settings_policy_deleted, payload: policy}, socket) do
    policies = Mrgr.List.remove(socket.assigns.policies, policy)

    socket
    |> Flash.put(:info, "Policy #{policy.title} was deleted.")
    |> assign(:policies, policies)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def repo_count(counts, %{id: id}) do
    counts
    |> Map.get(id)
    |> Enum.count()
  end
end
