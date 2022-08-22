defmodule MrgrWeb.FileChangeAlertLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      repos = Mrgr.Repository.for_user_with_rules(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:repos, repos)
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:repos, [])
      |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <!-- This example requires Tailwind CSS v2.0+ -->
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title="File Change Alerts" description="Add alerts based on custom file or folder names." />
      <div class="mt-8 flex flex-col">
        <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
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
                  <%= for repo <- @repos do %>
                    <tr class="border-t border-gray-200">
                      <th colspan="2" scope="colgroup" class="bg-gray-50 px-4 py-2 text-left text-sm font-semibold text-gray-900 sm:px-6">
                        <%= repo.name %>
                      </th>
                      <th colspan="1" scope="colgroup" class="bg-gray-50 px-4 py-2 text-right text-sm font-semibold text-gray-900 sm:px-6">
                        <%= link "Edit Alerts", to: Routes.file_change_alert_path(MrgrWeb.Endpoint, :edit, repo.name), class: "text-emerald-600 hover:text-emerald-900 hover:bg-emerald-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md" %>
                      </th>
                    </tr>

                    <%= for alert <- repo.file_change_alerts do %>
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
                  <% end %>

                  <!-- More people... -->
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
