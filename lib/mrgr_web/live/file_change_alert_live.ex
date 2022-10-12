defmodule MrgrWeb.FileChangeAlertLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      repos = Mrgr.Repository.for_user_with_rules(current_user)
      Mrgr.PubSub.subscribe_to_installation(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:form, nil)
      |> assign(:repos, repos)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-add-form", %{"id" => repo_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    changeset = empty_changeset()

    form = %{
      action: :create,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        bg_color: changeset.data.bg_color,
        badge_text: nil
      }
    }

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("edit-alert", %{"repo" => repo_id, "alert" => alert_id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, repo_id)
    alert = Mrgr.List.find(repo.file_change_alerts, alert_id)
    changeset = %{build_changeset(alert) | action: :update}

    form = %{
      action: :edit,
      repo: repo,
      changeset: changeset,
      badge_preview: %{
        bg_color: alert.bg_color,
        badge_text: alert.badge_text
      }
    }

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("close-form", _params, socket) do
    socket
    |> assign(:form, nil)
    |> noreply()
  end

  def handle_event("form-change", %{"file_change_alert" => params}, socket) do
    # used to trigger updates to label preview
    form = socket.assigns.form

    badge_preview = %{
      bg_color: params["bg_color"],
      badge_text: params["badge_text"]
    }

    # i'm only interested in the badge preview, but i need to set changeset
    # data here otherwise an unknown bug will clear out my :pattern field when
    # :badge_text is changed (but only when adding a new alert).
    form = %{
      form
      | badge_preview: badge_preview,
        changeset: build_changeset(form.changeset.data, params)
    }

    socket
    |> assign(:form, form)
    |> noreply()
  end

  def handle_event("save-file-alert", %{"file_change_alert" => params}, socket) do
    form = socket.assigns.form

    res =
      case form.action do
        :edit ->
          Mrgr.FileChangeAlert.update(form.changeset.data, params)

        :create ->
          params
          |> Map.put("repository_id", form.repo.id)
          |> Map.put("source", :user)
          |> Mrgr.FileChangeAlert.create()
      end

    case res do
      {:ok, _alert} ->
        socket
        |> assign(:form, nil)
        |> noreply()

      {:error, changeset} ->
        form = %{form | changeset: changeset}

        socket
        |> assign(:form, form)
        |> noreply()
    end
  end

  def handle_event("delete-alert", _params, socket) do
    alert = socket.assigns.form.changeset.data

    case Mrgr.Repo.delete(alert) do
      {:ok, alert} ->
        repos = remove_alert_from_its_repo(socket.assigns.repos, alert)

        socket
        |> assign(:repos, repos)
        |> assign(:form, nil)
        |> noreply()

      _que ->
        noreply(socket)
    end
  end

  def handle_info(%{event: @file_change_alert_created, payload: alert}, socket) do
    repos = add_alert_to_its_repo(socket.assigns.repos, alert)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(%{event: @file_change_alert_updated, payload: alert}, socket) do
    repos = update_alert_in_its_repo(socket.assigns.repos, alert)

    socket
    |> assign(:repos, repos)
    |> noreply()
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  defp remove_alert_from_its_repo(repos, alert) do
    repo = find_alert_repo(repos, alert)

    updated_alerts = Mrgr.List.remove(repo.file_change_alerts, alert)

    rebuild_repo_list_with_new_alerts(updated_alerts, repo, repos)
  end

  defp add_alert_to_its_repo(repos, alert) do
    repo = find_alert_repo(repos, alert)

    updated_alerts = [alert | repo.file_change_alerts]

    rebuild_repo_list_with_new_alerts(updated_alerts, repo, repos)
  end

  defp update_alert_in_its_repo(repos, alert) do
    repo = find_alert_repo(repos, alert)

    updated_alerts = Mrgr.List.replace(repo.file_change_alerts, alert)

    rebuild_repo_list_with_new_alerts(updated_alerts, repo, repos)
  end

  defp find_alert_repo(repos, alert) do
    Mrgr.List.find(repos, alert.repository_id)
  end

  defp rebuild_repo_list_with_new_alerts(alerts, repo, repos) do
    updated_repo = %{repo | file_change_alerts: alerts}

    Mrgr.List.replace(repos, updated_repo)
  end

  defp build_changeset(schema, params \\ %{}) do
    Mrgr.Schema.FileChangeAlert.changeset(schema, params)
  end

  defp empty_changeset do
    %Mrgr.Schema.FileChangeAlert{}
    |> build_changeset()
  end
end
