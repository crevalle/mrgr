defmodule MrgrWeb.FileChangeAlertEditLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_session, %{"user_id" => user_id, "repo_name" => name}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      repo = Mrgr.Repository.find_by_name_for_user(current_user, name)

      socket
      |> assign(:current_user, current_user)
      |> assign(:repo, repo)
      |> assign(:alerts, load_repo_alerts(repo))
      |> assign(:cs, empty_changeset())
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:repo, nil)
      |> assign(:alerts, [])
      |> assign(:cs, empty_changeset())
      |> ok()
    end
  end

  def load_repo_alerts(repo) do
    Mrgr.FileChangeAlert.for_repository(repo)
    |> Enum.map(fn a ->
      {a, build_changeset(a)}
    end)
  end

  # protects against random id injection
  # slightly different from our usual list-handling stuff
  # because we also store a changeset for each alert
  defp fetch_alert(socket, id) when is_bitstring(id),
    do: fetch_alert(socket, String.to_integer(id))

  defp fetch_alert(%{assigns: %{alerts: alerts}}, alert_id) do
    Enum.find(alerts, fn {alert, _cs} -> alert.id == alert_id end)
  end

  defp remove_alert_from_list(socket, id) when is_bitstring(id),
    do: remove_alert_from_list(socket, String.to_integer(id))

  defp remove_alert_from_list(%{assigns: %{alerts: alerts}}, alert_id) do
    Enum.reject(alerts, fn {a, _cs} -> a.id == alert_id end)
  end

  defp update_alert_in_list(%{assigns: %{alerts: alerts}}, alert) do
    idx = Enum.find_index(alerts, fn {a, _cs} -> a.id == alert.id end)
    List.replace_at(alerts, idx, {alert, build_changeset(alert)})
  end

  defp update_changeset_in_list(%{assigns: %{alerts: alerts}}, alert, cs) do
    idx = Enum.find_index(alerts, fn {a, _cs} -> a.id == alert.id end)
    List.replace_at(alerts, idx, {alert, cs})
  end

  def handle_event("update-alert", %{"file_change_alert" => params}, socket) do
    {alert, _cs} = fetch_alert(socket, params["id"])

    case Mrgr.FileChangeAlert.update(alert, params) do
      {:ok, updated} ->
        alerts = update_alert_in_list(socket, updated)

        socket
        |> put_flash(:info, "Alert updated.")
        |> assign(:alerts, alerts)
        |> noreply()

      {:error, cs} ->
        alerts = update_changeset_in_list(socket, alert, cs)

        socket
        |> put_flash(:error, "Couldn't update alert : (")
        |> assign(:alerts, alerts)
        |> noreply()
    end
  end

  def handle_event("save-file-alert", %{"file_change_alert" => params}, socket) do
    params = Map.put(params, "repository_id", socket.assigns.repo.id)

    params
    |> Mrgr.FileChangeAlert.create()
    |> case do
      {:ok, alert} ->
        new_alert = {alert, build_changeset(alert)}
        alerts = [new_alert | socket.assigns.alerts]

        socket
        |> assign(:alerts, alerts)
        |> assign(:cs, empty_changeset())
        |> noreply()

      {:error, cs} ->
        socket
        |> assign(:cs, cs)
        |> noreply()
    end
  end

  def handle_event("delete", %{"alert-id" => id}, socket) do
    {alert, _cs} = fetch_alert(socket, id)

    case Mrgr.FileChangeAlert.delete(alert) do
      {:ok, _struct} ->
        alerts = remove_alert_from_list(socket, id)

        socket
        |> put_flash(:info, "Alert Deleted.")
        |> assign(:alerts, alerts)
        |> noreply()

      {:error, _cs} ->
        socket
        |> put_flash(:error, "Couldn't delete alert : (")
        |> noreply()
    end
  end

  defp build_changeset(schema) do
    Mrgr.Schema.FileChangeAlert.changeset(schema, %{})
  end

  defp empty_changeset(params \\ %{}) do
    Mrgr.Schema.FileChangeAlert.changeset(%Mrgr.Schema.FileChangeAlert{}, params)
  end
end
