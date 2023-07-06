defmodule MrgrWeb.NotificationLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event
  import MrgrWeb.Components.NotificationPreference

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      socket = set_user_installing_slackbot_redirect(socket)

      Mrgr.PubSub.subscribe_to_installation(socket.assigns.current_user)

      preferences = Mrgr.User.notification_preferences(socket.assigns.current_user)

      slack_unconnected =
        !Mrgr.Installation.slack_connected?(socket.assigns.current_user.current_installation)

      pr_tabs = Mrgr.PRTab.for_user(socket.assigns.current_user)

      repos = Mrgr.Repository.for_user_with_hif_rules(socket.assigns.current_user)

      socket
      |> put_title("Realtime Alerts")
      |> assign(:changeset, nil)
      |> assign(:hif_form, nil)
      |> assign(:preferences, preferences)
      |> assign(:slack_unconnected, slack_unconnected)
      |> assign(:repos, repos)
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

  def handle_event("add-hif", %{"id" => repo_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    changeset = build_hif_changeset(%Mrgr.Schema.HighImpactFileRule{})

    form = build_hif_form(:create, repo, changeset)

    socket
    |> assign(:hif_form, form)
    |> noreply()
  end

  def handle_event("edit-hif", %{"repo" => repo_id, "hif" => hif_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    hif = Mrgr.List.find(repo.high_impact_file_rules, hif_id)
    changeset = %{build_hif_changeset(hif) | action: :update}

    form = build_hif_form(:edit, repo, changeset, hif)

    socket
    |> assign(:hif_form, form)
    |> noreply()
  end

  def handle_event("cancel-edit", _attrs, socket) do
    socket
    |> assign(:hif_form, nil)
    |> noreply()
  end

  def handle_event("form-change", %{"high_impact_file_rule" => params}, socket) do
    # used to trigger updates to label preview
    form = socket.assigns.hif_form

    badge_preview = %{
      color: params["color"],
      name: params["name"]
    }

    # i'm only interested in the badge preview, but i need to set changeset
    # data here otherwise an unknown bug will clear out my :pattern field when
    # :name is changed (but only when adding a new hif).
    form = %{
      form
      | badge_preview: badge_preview,
        changeset: build_hif_changeset(form.changeset.data, params)
    }

    socket
    |> assign(:hif_form, form)
    |> noreply()
  end

  def handle_event("save-hif", %{"high_impact_file_rule" => params}, socket) do
    form = socket.assigns.hif_form

    res =
      case form.action do
        :edit ->
          Mrgr.HighImpactFileRule.update(form.changeset.data, params)

        :create ->
          params
          |> Map.put("repository_id", form.repo.id)
          |> Map.put("user_id", socket.assigns.current_user.id)
          |> Map.put("source", :user)
          |> Mrgr.HighImpactFileRule.create()
      end

    case res do
      {:ok, _hif} ->
        socket
        |> assign(:hif_form, nil)
        |> hide_detail()
        |> Flash.put(:info, "Alert saved ✌️")
        |> noreply()

      {:error, changeset} ->
        form = %{form | changeset: changeset}

        socket
        |> assign(:hif_form, form)
        |> noreply()
    end
  end

  def handle_event("delete-hif", _params, socket) do
    hif = socket.assigns.hif_form.changeset.data

    case Mrgr.Repo.delete(hif) do
      {:ok, hif} ->
        repos = remove_hif_from_its_repo(socket.assigns.repos, hif)

        socket
        |> assign(:repos, repos)
        |> assign(:hif_form, nil)
        |> hide_detail()
        |> Flash.put(:info, "Alert deleted ✌️")
        |> noreply()

      _que ->
        noreply(socket)
    end
  end

  def handle_info({:hif_updated, hif}, socket) do
    repos = update_hif_in_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: @high_impact_file_rule_created, payload: hif}, socket) do
    repos = add_hif_to_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: @high_impact_file_rule_updated, payload: hif}, socket) do
    repos = update_hif_in_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info({:channel_updated, %Mrgr.Schema.HighImpactFileRule{} = hif}, socket) do
    repos = update_hif_in_its_repo(socket.assigns.repos, hif)

    socket
    |> assign(:repos, repos)
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

  defp remove_hif_from_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = Mrgr.List.remove(repo.high_impact_file_rules, hif)

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp add_hif_to_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = [hif | repo.high_impact_file_rules]

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp update_hif_in_its_repo(repos, hif) do
    repo = find_hif_repo(repos, hif)

    updated_hifs = Mrgr.List.replace(repo.high_impact_file_rules, hif)

    rebuild_repo_list_with_new_hifs(updated_hifs, repo, repos)
  end

  defp find_hif_repo(repos, hif) do
    Mrgr.List.find(repos, hif.repository_id)
  end

  defp rebuild_repo_list_with_new_hifs(hifs, repo, repos) do
    updated_repo = %{repo | high_impact_file_rules: hifs}

    Mrgr.List.replace(repos, updated_repo)
  end

  defp build_hif_changeset(schema, params \\ %{}) do
    Mrgr.Schema.HighImpactFileRule.changeset(schema, params)
  end

  def build_hif_form(:create, repo, changeset) do
    %{
      action: :create,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        color: changeset.data.color,
        name: nil
      }
    }
  end

  def build_hif_form(:edit, repo, changeset, hif) do
    %{
      action: :edit,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        color: hif.color,
        name: hif.name
      }
    }
  end
end
