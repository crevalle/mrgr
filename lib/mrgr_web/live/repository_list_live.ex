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

      profiles =
        Mrgr.RepositorySecurityProfile.for_installation(current_user.current_installation)

      repo_counts =
        Mrgr.Repository.id_counts_for_profiles(Enum.map(profiles, & &1.id))
        |> IO.inspect()

      socket
      |> assign(:repos, repos)
      |> assign(:repo_counts, repo_counts)
      |> assign(:form_subject, nil)
      |> assign(:profiles, profiles)
      |> put_title("Repositories")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-form", _params, socket) do
    socket
    |> assign(:form_subject, %Mrgr.Schema.RepositorySecurityProfile{})
    |> noreply()
  end

  def handle_event("edit-profile", %{"id" => id}, socket) do
    profile =
      socket.assigns.profiles
      |> Mrgr.List.find(id)

    socket
    |> assign(:form_subject, profile)
    |> noreply()
  end

  def handle_info(:close_form, socket) do
    socket
    |> assign(:form_subject, nil)
    |> noreply()
  end

  def handle_info(%{event: @security_profile_created, payload: profile}, socket) do
    profiles = [profile | socket.assigns.profiles]
    profiles = Enum.sort_by(profiles, & &1.title)

    repo_counts = Mrgr.Repository.id_counts_for_profiles(Enum.map(profiles, & &1.id))

    socket
    |> Flash.put(:info, "Security Profile #{profile.title} was added.")
    |> assign(:profiles, profiles)
    |> assign(:repo_counts, repo_counts)
    |> noreply()
  end

  def handle_info(%{event: @security_profile_updated, payload: profile}, socket) do
    profiles = Mrgr.List.replace(socket.assigns.profiles, profile)

    repo_counts = Mrgr.Repository.id_counts_for_profiles(Enum.map(profiles, & &1.id))

    socket
    |> Flash.put(:info, "Security Profile #{profile.title} was updated.")
    |> assign(:profiles, profiles)
    |> assign(:repo_counts, repo_counts)
    |> noreply()
  end

  def handle_info(%{event: @security_profile_deleted, payload: profile}, socket) do
    profiles = Mrgr.List.remove(socket.assigns.profiles, profile)

    socket
    |> Flash.put(:info, "Security Profile #{profile.title} was deleted.")
    |> assign(:profiles, profiles)
    |> noreply()
  end

  def handle_info(%{event: _whatevs}, socket), do: noreply(socket)

  def repo_count(counts, %{id: id}) do
    counts
    |> Map.get(id)
    |> Enum.count()
  end
end
