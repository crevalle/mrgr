defmodule MrgrWeb.FileChangeAlertLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      repos = Mrgr.Repository.for_user_with_rules(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:selected_repo_id, nil)
      |> assign(:changeset, nil)
      |> assign(:repos, repos)
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("open-add-form", %{"repo-id" => id}, socket) do
    socket
    |> assign(:selected_repo_id, id)
    |> assign(:changeset, empty_changeset())
    |> noreply()
  end

  def handle_event("form-change", %{"file_change_alert" => params}, socket) do
    changeset =
      %Mrgr.Schema.FileChangeAlert{}
      |> build_changeset(params)

    socket
    |> assign(:cs, changeset)
    |> noreply()
  end

  def handle_event("save-file-alert", %{"file_change_alert" => params}, socket) do
    params =
      params
      |> Map.put("repository_id", socket.assigns.selected_repo_id)
      |> Map.put("source", :user)

    params
    |> Mrgr.FileChangeAlert.create()
    |> case do
      {:ok, alert} ->
        new_alert = {alert, build_changeset(alert)}
        alerts = [new_alert | socket.assigns.alerts]

        socket
        |> assign(:selected_repo_id, nil)
        |> assign(:cs, nil)
        |> noreply()

      {:error, cs} ->
        socket
        |> assign(:cs, cs)
        |> noreply()
    end
  end

  defp build_changeset(schema, params \\ %{}) do
    Mrgr.Schema.FileChangeAlert.changeset(schema, params)
  end

  defp empty_changeset do
    build_changeset(%Mrgr.Schema.FileChangeAlert{})
  end
end
