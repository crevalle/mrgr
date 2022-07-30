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

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="mt-8 sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-xl font-semibold text-gray-900">Editing Alerts for <%= @repo.full_name %></h1>
          <p class="mt-2 text-sm text-gray-700">Add alerts based on custom file or folder names.</p>
        </div>
      </div>

      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">

          <div class="mt-1">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Add New Alert</h3>
            <p class="my-1 max-w-2xl text-sm text-gray-500">Badges may be reused across patterns.</p>
          </div>

          <.form let={f} for={@cs}  phx-submit="save_file_alert" class="space-y-8 divide-y divide-gray-200">
            <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5">
              <%= label(f, :pattern, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
              <div class="mt-1 sm:mt-0 sm:col-span-2">
                <%= text_input f, :pattern, placeholder: "example: 'foo/bar.ex' or 'foo/**/bar.ex'", class: "max-w-lg block w-full shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                <%= error_tag(f, :pattern, class: "mt-2 text-sm text-red-600") %>
                <p class="mt-2 text-sm text-gray-500" id="pattern-description">A file or folder name.</p>
              </div>
            </div>

            <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5">
              <%= label(f, :badge_text, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
              <div class="mt-1 sm:mt-0 sm:col-span-2">
                <%= text_input f, :badge_text, placeholder: "example: 'user model'", class: "max-w-lg block w-full shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                <%= error_tag(f, :badge_text, class: "mt-2 text-sm text-red-600") %>
                <p class="mt-2 text-sm text-gray-500" id="badge_text-description">The text of the alert badge.</p>
              </div>
            </div>

            <div class="pt-5">
              <div class="flex justify-end">
                <button type="submit" class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-emerald-600 hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500">Save</button>
              </div>
            </div>
          </.form>
        </div>
      </div>


      <div class="mt-8 bg-white overflow-hidden shadow rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <div class="mt-1">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Existing Alerts</h3>
            <p class="my-1 max-w-2xl text-sm text-gray-500">Edit them here!</p>
          </div>

          <!-- table -->
          <div class="flex flex-col min-w-full">
            <!-- table header row -->
              <div class="flex">
                <div class="flex-1 py-3.5 text-left text-sm font-semibold text-gray-900">Pattern</div>
                <div class="flex-1 px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Label</div>
                <div class="flex"></div>
              </div>
            <!-- table body -->
              <div class="divide-y divide-gray-200">
                <%= for {alert, cs} <- @alerts do %>
                  <.form let={f} for={cs} phx-submit="update-alert" class="space-y-8">
                    <!-- table row -->
                    <div class="flex py-4">
                      <!-- tds -->
                      <div class="flex flex-col flex-1">
                        <%= hidden_input f, :id %>
                        <%= text_input f, :pattern, placeholder: "example: 'foo/bar.ex' or 'foo/**/bar.ex'", class: "max-w-lg block w-full shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                        <%= error_tag(f, :pattern, class: "mt-2 text-sm text-red-600") %>
                      </div>
                      <div class="flex flex-col flex-1">
                        <%= text_input f, :badge_text, placeholder: "example: 'foo/bar.ex' or 'foo/**/bar.ex'", class: "max-w-lg block w-full shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                        <%= error_tag(f, :badge_text, class: "mt-2 text-sm text-red-600") %>
                      </div>
                      <div class="flex">
                        <div>
                          <%= submit "Save", class: "ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-emerald-600 hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500" %>
                        </div>
                        <div>
                          <%= link "Delete", to: "#", data: [confirm: "Sure about that?"], phx_click: "delete", phx_value_alert_id: alert.id, class: "btn ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-rose-600 hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500" %>
                        </div>
                      </div>
                    </div>
                  </.form>
                <% end %>
              </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def load_repo_alerts(repo) do
    Mrgr.FileChangeAlert.for_repository(repo)
    |> Enum.map(fn a ->
      {a, build_changeset(a)}
    end)
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

  # protects against random id injection
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

  defp update_alert_in_list(%{assigns: %{alerts: alerts}}, alert) do
    idx = Enum.find_index(alerts, fn {a, _cs} -> a.id == alert.id end)
    List.replace_at(alerts, idx, {alert, build_changeset(alert)})
  end

  defp update_changeset_in_list(%{assigns: %{alerts: alerts}}, alert, cs) do
    idx = Enum.find_index(alerts, fn {a, _cs} -> a.id == alert.id end)
    List.replace_at(alerts, idx, {alert, cs})
  end

  def handle_event("save_file_alert", %{"file_change_alert" => params}, socket) do
    params = Map.put(params, "repository_id", socket.assigns.repo.id)

    params
    |> Mrgr.FileChangeAlert.create()
    |> case do
      {:ok, alert} ->
        alerts = [alert | socket.assigns.alerts] |> Enum.sort_by(& &1.pattern)

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

  defp build_changeset(schema) do
    Mrgr.Schema.FileChangeAlert.changeset(schema, %{})
  end

  defp empty_changeset(params \\ %{}) do
    Mrgr.Schema.FileChangeAlert.changeset(%Mrgr.Schema.FileChangeAlert{}, params)
  end
end
