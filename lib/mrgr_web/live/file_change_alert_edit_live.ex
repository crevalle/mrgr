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

            <!-- Content goes here -->
            <!-- We use less vertical padding on card headers on desktop than on body sections -->
            <.form let={f} for={@cs}  phx-submit="save_file_alert" class="space-y-8 divide-y divide-gray-200">
              <div class="space-y-8 divide-y divide-gray-200 sm:space-y-5">
                <div>
                  <div>
                    <h3 class="text-lg leading-6 font-medium text-gray-900">Add New Alert</h3>
                    <p class="my-1 max-w-2xl text-sm text-gray-500">Badges may be reused across patterns.</p>
                  </div>

                  <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5">
                    <%= label(f, :pattern, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
                    <div class="mt-1 sm:mt-0 sm:col-span-2">
                      <%= text_input f, :pattern, placeholder: "example: 'foo/bar.ex' or 'foo/**/bar.ex'", class: "max-w-lg block w-full shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                      <%= error_tag(f, :pattern, class: "mt-2 text-sm text-red-600") %>
                      <p class="mt-2 text-sm text-gray-500" id="pattern-description">A file or folder name.</p>
                    </div>
                  </div>

                  <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5">
                    <%= label(f, :badge_text, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
                    <div class="mt-1 sm:mt-0 sm:col-span-2">
                      <%= text_input f, :badge_text, placeholder: "example: 'user model'", class: "max-w-lg block w-full shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md" %>
                      <%= error_tag(f, :badge_text, class: "mt-2 text-sm text-red-600") %>
                      <p class="mt-2 text-sm text-gray-500" id="badge_text-description">The text of the alert label.</p>
                    </div>
                  </div>

                </div>
              </div>

              <div class="pt-5">
                <div class="flex justify-end">
                  <button type="submit" class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">Save</button>
                </div>
              </div>
            </.form>

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
