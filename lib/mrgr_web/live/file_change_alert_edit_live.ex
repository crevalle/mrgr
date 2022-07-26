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
      |> assign(:cs, build_changeset())
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:repo, nil)
      |> assign(:alerts, [])
      |> assign(:cs, build_changeset())
      |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-xl font-semibold text-gray-900">Editing Alerts for <%= @repo.name %></h1>
          <p class="mt-2 text-sm text-gray-700">Add alerts based on custom file or folder names.</p>
        </div>
      </div>

      <div class="mt-8 flex flex-col">
        <div class="bg-white overflow-hidden shadow rounded-lg divide-y divide-gray-200">
          <div class="px-4 py-5 sm:px-6">

            <div class="flex flex-col">
              <h3 class="text-sm font-medium pb-5">Add New Alert</h3>
              <!-- Content goes here -->
              <!-- We use less vertical padding on card headers on desktop than on body sections -->
              <div class="">
                <.form let={f} for={@cs}  phx-submit="save_file_alert" class="flex justify-between items-start">

                  <div>
                    <div class="relative border border-gray-300 rounded-md px-3 py-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
                      <label for="pattern" class="absolute -top-2 left-2 -mt-px inline-block px-1 bg-white text-xs font-medium text-gray-900">Pattern</label>
                      <div class="mt-1">
                        <%= text_input f, :pattern, placeholder: "example: 'foo/bar.ex' or 'foo/**/bar.ex'", class: "block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm" %>
                      </div>
                    </div>
                    <%= error_tag(f, :pattern, class: "mt-2 text-sm text-red-600") %>
                    <p class="mt-2 text-sm text-gray-500" id="pattern-description">A file or folder name</p>
                  </div>

                  <div>
                    <div class="relative border border-gray-300 rounded-md px-3 py-2 shadow-sm focus-within:ring-1 focus-within:ring-indigo-600 focus-within:border-indigo-600">
                      <label for="badge" class="absolute -top-2 left-2 -mt-px inline-block px-1 bg-white text-xs font-medium text-gray-900">Badge</label>
                      <div class="mt-1">
                        <%= text_input f, :badge_text, placeholder: "example: 'user model'", class: "block w-full border-0 p-0 text-gray-900 placeholder-gray-500 focus:ring-0 sm:text-sm" %>
                      </div>
                    </div>
                    <%= error_tag(f, :badge_text, class: "mt-2 text-sm text-red-600") %>
                    <p class="mt-2 text-sm text-gray-500" id="badge-description">The text of the alert label.</p>
                  </div>


                  <%= submit "Save", class: "inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:w-auto" %>
                </.form>

              </div>
            </div>
          </div>
        </div>
        <div class="bg-white overflow-hidden shadow rounded-lg divide-y divide-gray-200">
          <div class="px-4 py-5 sm:px-6">

            <!-- Content goes here -->
            <h3 class="text-sm font-medium">Existing Alerts</h3>
            <table class="min-w-full">
              <thead class="bg-white">
                <tr>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Pattern</th>
                  <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Label</th>
                  <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                    <span class="sr-only">Edit</span>
                    <span class="sr-only">Delete</span>
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white">
                <%= for alert <- @alerts do %>
                  <tr class="border-t border-gray-300">
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6"><pre>'<%= alert.pattern %>'</pre></td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      <MrgrWeb.Component.PendingMerge.badge bg="bg-gray-100" text="text-gray-800">
                        <%= alert.badge_text %>
                      </MrgrWeb.Component.PendingMerge.badge>
                    </td>
                    <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                    </td>
                  </tr>

                <% end %>

                <!-- More people... -->
              </tbody>
            </table>
          </div>
        </div>



      </div>
    </div>

    """
  end

  def load_repo_alerts(repo) do
    Mrgr.FileChangeAlert.for_repository(repo)
  end

  def handle_event("save_file_alert", %{"file_change_alert" => params}, socket) do
    params = Map.put(params, "repository_id", socket.assigns.repo.id)

    params
    |> build_changeset()
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, alert} ->
        alerts = [alert | socket.assigns.alerts] |> Enum.sort_by(& &1.pattern)

        socket
        |> assign(:alerts, alerts)
        |> assign(:cs, build_changeset())
        |> noreply()

      {:error, cs} ->
        socket
        |> assign(:cs, cs)
        |> noreply()
    end
  end

  defp build_changeset(params \\ %{}) do
    Mrgr.Schema.FileChangeAlert.changeset(%Mrgr.Schema.FileChangeAlert{}, params)
  end
end
