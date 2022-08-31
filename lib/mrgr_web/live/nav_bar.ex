defmodule MrgrWeb.Live.NavBar do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)

      {:ok, assign(socket, :current_user, current_user)}
    else
      {:ok, assign(socket, :current_user, nil)}
    end
  end

  def render(assigns) do
    ~H"""

      <div class="sticky top-0 z-10 flex-shrink-0 flex h-16 bg-white shadow">
        <button type="button" class="px-4 border-r border-gray-200 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500 md:hidden">
          <span class="sr-only">Open sidebar</span>
          <!-- Heroicon name: outline/menu-alt-2 -->
          <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h7" />
          </svg>
        </button>
        <div class="flex-1 px-4 flex justify-between">
          <div class="ml-4 flex items-center md:ml-6">
            <%= link to: Routes.pending_merge_path(MrgrWeb.Endpoint, :index), class: "text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md" do %>
              <.icon name="share" type="outline" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6" />
              <span class="flex-1"> Pending Merges </span>

              <!-- Current: "bg-white", Default: "bg-gray-100 group-hover:bg-gray-200" -->
              <span class="bg-gray-100 group-hover:bg-gray-200 ml-3 inline-block py-0.5 px-3 text-xs font-medium rounded-full"> 3 </span>
            <% end %>

            <%= link to: Routes.file_change_alert_path(MrgrWeb.Endpoint, :index), class: "text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md" do %>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.348 14.651a3.75 3.75 0 010-5.303m5.304 0a3.75 3.75 0 010 5.303m-7.425 2.122a6.75 6.75 0 010-9.546m9.546 0a6.75 6.75 0 010 9.546M5.106 18.894c-3.808-3.808-3.808-9.98 0-13.789m13.788 0c3.808 3.808 3.808 9.981 0 13.79M12 12h.008v.007H12V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
              </svg>
              <span class="flex-1"> File Change Alerts </span>
            <% end %>

            <%= if admin?(@current_user) do %>
              <%= link to: Routes.admin_incoming_webhook_path(MrgrWeb.Endpoint, :index), class: "text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md" do %>

                <.icon name="globe-alt" type="outline" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6" />
                <span class="flex-1"> Admin - Incoming Webhooks </span>
              <% end %>

              <%= link to: Routes.admin_user_path(MrgrWeb.Endpoint, :index), class: "text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md" do %>

                <.icon name="users" type="outline" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6" />
                <span class="flex-1"> Admin - Users </span>
              <% end %>
            <% end %>

            <!-- Profile dropdown -->
            <div class="ml-3 relative">
              <div>
                <.button phx-click={Phoenix.LiveView.JS.toggle(
                    to: "#user-menu",
                    in: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"},
                    out: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
                  )}
                  colors="bg-white focus:ring-indigo-500"
                  id="user-menu-button"
                  aria-expanded="false"
                  aria-haspopup="true">
                  <span class="sr-only">Open user menu</span>

                  <%= img_tag @current_user.image, class: "h-8 w-8 rounded-full", alt: @current_user.name %>
                  <.icon name="chevron-down" type="outline" class="-mr-1 ml-2 h-5 w-5" />
                </.button>
              </div>

              <div id="user-menu" style="display: none;" class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none" role="menu" aria-orientation="vertical" aria-labelledby="user-menu-button" tabindex="-1">
                <%= link to: Routes.repository_path(MrgrWeb.Endpoint, :index), class: "text-gray-700 hover:text-gray-900 hover:bg-gray-100 group flex items-center px-2 py-2 text-sm rounded-md", role: "menuitem", tabindex: "-1"  do %>
                  <.icon name="newspaper" type="outline" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6" />
                  <span class="flex-1">Repositories</span>
                <% end %>

                <%= link to: Routes.auth_path(MrgrWeb.Endpoint, :delete), method: "delete", data_confirm: "Ready to go?", class: "text-gray-700 hover:text-gray-900 hover:bg-gray-100 group flex items-center px-2 py-2 text-sm rounded-md", role: "menuitem", tabindex: "-1"  do %>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75" />
                  </svg>
                  <span class="flex-1">Sign Out</span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    """
  end
end
