defmodule MrgrWeb.NotificationLive do
  use MrgrWeb, :live_view
  import MrgrWeb.Components.NotificationPreference

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      socket = set_user_installing_slackbot_redirect(socket)

      preferences = Mrgr.User.notification_preferences(socket.assigns.current_user)

      hifs_by_repo =
        Mrgr.HighImpactFileRule.for_user_with_repo(socket.assigns.current_user) |> group_by_repo()

      slack_unconnected =
        !Mrgr.Installation.slack_connected?(socket.assigns.current_user.current_installation)

      pr_tabs = Mrgr.PRTab.for_user(socket.assigns.current_user)

      socket
      |> put_title("Your Profile")
      |> assign(:changeset, nil)
      |> assign(:preferences, preferences)
      |> assign(:slack_unconnected, slack_unconnected)
      |> assign(:hifs_by_repo, hifs_by_repo)
      |> assign(:pr_tabs, pr_tabs)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("edit", _params, socket) do
    socket
    |> assign(:changeset, build_changeset(socket.assigns.current_user))
    |> noreply()
  end

  def handle_event("save", %{"user" => params}, socket) do
    socket.assigns.current_user
    |> build_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:error, cs} ->
        socket
        |> assign(:changeset, cs)
        |> noreply()

      {:ok, user} ->
        socket
        |> Flash.put(:info, "Updated!")
        |> assign(:current_user, user)
        |> assign(:changeset, nil)
        |> noreply()
    end
  end

  def handle_event("update-weekly-changelog-preference", %{"user" => params}, socket) do
    socket.assigns.current_user
    |> Mrgr.Schema.User.weekly_changelog_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, user} ->
        socket
        |> Flash.put(:info, "Updated!")
        |> assign(:current_user, user)
        |> noreply()

      {:error, _cs} ->
        socket
        |> Flash.put(:error, "Couldn't perform update : /")
        |> noreply()
    end
  end

  def handle_info({:channel_updated, %Mrgr.Schema.HighImpactFileRule{} = hif}, socket) do
    hifs = Mrgr.List.replace(socket.assigns.hifs_by_repo[hif.repository], hif)

    hifs_by_repo = Map.put(socket.assigns.hifs_by_repo, hif.repository, hifs)

    socket
    |> assign(:hifs_by_repo, hifs_by_repo)
    |> Flash.put(:info, "Updated!")
    |> noreply()
  end

  def handle_info(
        {:channel_updated, %Mrgr.Schema.UserNotificationPreference{} = preference},
        socket
      ) do
    preferences = Mrgr.List.replace(socket.assigns.preferences, preference)

    socket
    |> assign(:preferences, preferences)
    |> Flash.put(:info, "Updated!")
    |> noreply()
  end

  def handle_info({:channel_updated, %Mrgr.Schema.PRTab{} = tab}, socket) do
    tabs = Mrgr.List.replace(socket.assigns.pr_tabs, tab)

    socket
    |> assign(:pr_tabs, tabs)
    |> Flash.put(:info, "Updated!")
    |> noreply()
  end

  def handle_info(
        {:preference_updated, %Mrgr.Schema.UserNotificationPreference{} = preference},
        socket
      ) do
    preferences = Mrgr.List.replace(socket.assigns.preferences, preference)

    socket
    |> assign(:preferences, preferences)
    |> Flash.put(:info, "Updated!")
    |> noreply()
  end

  def build_changeset(user, params \\ %{}) do
    user
    |> Mrgr.Schema.User.notification_changeset(params)
  end

  def group_by_repo(hifs) do
    Enum.group_by(hifs, & &1.repository)
  end

  # a one-way flag
  # if a user installs slack during onboarding this doesn't change,
  # but will change the first time they come to notifications page.
  #
  # send them back here if it's where they started
  defp set_user_installing_slackbot_redirect(socket) do
    user =
      socket.assigns.current_user
      |> Ecto.Changeset.change(%{installing_slackbot_from_profile_page: true})
      |> Mrgr.Repo.update!()

    socket
    |> assign(:current_user, user)
  end
end
