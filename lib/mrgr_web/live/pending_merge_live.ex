defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      merges = Mrgr.Merge.pending_merges(current_user)
      repos = Mrgr.Repository.for_user_with_rules(current_user)
      frozen_repos = frozen_repos(repos)
      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:pending_merges, merges)
      |> assign(:selected_merge, nil)
      |> assign(:repos, repos)
      |> assign(:frozen_repos, frozen_repos)
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:pending_merges, [])
      |> assign(:selected_merge, nil)
      |> assign(:repos, [])
      |> assign(:frozen_repos, [])
      |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 pt-4 sm:px-6 lg:px-8">
      <div class="flex justify-between">
        <.heading title="Pending Merges" />

        <div class="relative inline-block text-left">
          <div>
            <.button phx-click={JS.toggle(
                to: "#merge-freeze-menu",
                in: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"},
                out: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
              )}
              colors="bg-blue-600 hover:bg-blue-700 focus:ring-blue-500"
              id="menu-button"
              aria-expanded="true"
              aria-haspopup="true">
              Freeze Merging
              <.icon name="chevron-down" type="outline" class="-mr-1 ml-2 h-5 w-5" />
            </.button>
          </div>

          <div style="display: none;" id="merge-freeze-menu" class="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none" role="menu" aria-orientation="vertical" aria-labelledby="menu-button" tabindex="-1">
            <div class="py-1" role="none">
              <%= for r <- @repos do %>
                <%= link to: "#", phx_click: "toggle_merge_freeze", phx_value_repo_id: r.id, data_confirm: "Sure about that?", class: "text-gray-700 block my-2 text-sm outline-none", role: "menuitem", tabindex: "-1", id: "repo-menu-item-#{r.id}" do %>
                  <div class="flex items-center hover:bg-gray-50">
                    <div class="basis-8 text-blue-400 ml-2">
                      <%= if r.merge_freeze_enabled do %>
                      ❄️
                      <% end %>
                    </div>
                    <%= r.name %>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>


      <%= if Enum.count(@frozen_repos) > 0 do %>
        <div class="flex flex-col my-4 p-4 rounded-md border border-blue-700 bg-blue-50">

          <.h3 color="text-blue-600">❄️ There is a Merge Freeze in effect❄️</.h3>
          <p class="my-3">PR merging is disabled for the following repos:</p>
          <ul class="list-disc my-3 mx-6">
            <%= for r <- @frozen_repos do %>
              <li>
                <%= r.name %>
              </li>
            <% end %>
          </ul>

          <p class="my-3">To resume merging for these repos, disable the Merge Freeze.</p>

        </div>
      <% end %>

      <div class="flex mt-8 space-x-4">
        <div class="basis-1/2 bg-white px-2 py-5 sm:px-6 overflow-hidden shadow rounded-lg">

          <div class="shadow overflow-hidden sm:rounded-md" phx-hook="Drag" id="drag">

            <ul role="list" class="divide-y divide-gray-200 dropzone" id="pending-merge-list">
              <%= for merge <- assigns.pending_merges do %>
                <%= link to: "#", phx_click: "show_preview", phx_value_merge_id: merge.id, class: "text-sm font-medium text-teal-500 truncate" do %>
                  <li draggable="true" class="draggable merge-list" id={"merge-#{merge.id}"}>
                    <div class="block hover:bg-gray-50">
                      <div class="px-4 py-4 sm:px-6">
                        <div class="flex items-center justify-between">
                          <.h3><%= merge.title %></.h3>
                          <div class="ml-2 flex-shrink-0 flex">
                            <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                              <p class="truncate max-w-xs">
                                "<%= Mrgr.Schema.Merge.head_commit_message(merge) %>"
                              </p>
                            </div>
                          </div>
                        </div>
                        <div class="mt-2 sm:flex sm:justify-between">
                          <div class="sm:flex">
                            <p class={"flex items-center text-sm #{repo_text_color(@repos, merge.repository)}"}>
                              <.icon name="users" type="solid" class="flex-shrink-0 mr-1.5 h-5 w-5" />
                              <%= merge.repository.name %>
                            </p>
                            <p class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                              <.icon name="location-marker" type="solid" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
                              <%= merge.merge_queue_index %>
                            </p>
                            <%= MrgrWeb.Component.PendingMerge.change_badges(%{merge: merge}) %>
                          </div>
                          <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <p>
                              <%= shorten_sha(merge.head.sha) %> by <%= Mrgr.Schema.Merge.head_committer(merge) %>
                            </p>
                          </div>
                        </div>
                        <div class="mt-2 sm:flex sm:justify-between items-start">
                          <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <p>Opened
                              <%= ts(merge.opened_at, assigns.timezone) %>
                            </p>
                          </div>
                          <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                            <p>
                              <%= ts(Mrgr.Schema.Merge.head_committed_at(merge), assigns.timezone) %>
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </li>
                <% end %>
              <% end %>
            </ul>

          </div>
        </div>

        <.live_component module={MrgrWeb.Components.Live.MergePreviewComponent} id="merge_preview" merge={@selected_merge} current_user={@current_user} frozen_repos={@frozen_repos}/>
      </div>
    </div>
    <.button phx-click="refresh" colors="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500"> Refresh PRs</.button>

    """
  end

  def handle_event("toggle_merge_freeze", %{"repo-id" => id}, socket) do
    repo = Mrgr.Utils.find_item_in_list(socket.assigns.repos, id)

    updated = Mrgr.Repository.toggle_merge_freeze(repo)

    updated_list = Mrgr.Utils.replace_item_in_list(socket.assigns.repos, updated)
    frozen_repos = frozen_repos(updated_list)

    socket
    |> assign(:repos, updated_list)
    |> assign(:frozen_repos, frozen_repos)
    |> noreply()
  end

  def handle_event("dropped", %{"draggedId" => id, "draggableIndex" => index}, socket) do
    dragged = find_dragged(socket.assigns.pending_merges, get_id(id))

    merges =
      socket.assigns.pending_merges
      |> update_merge_order(dragged, index)

    socket
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  def handle_event("show_preview", %{"merge-id" => id}, socket) do
    selected = Mrgr.Utils.find_item_in_list(socket.assigns.pending_merges, id)

    socket
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user

    # dangerous!  anyone can do this right now.
    installation = Mrgr.Repo.preload(user.current_installation, :repositories)
    Mrgr.Installation.refresh_merges!(installation)

    merges = Mrgr.Merge.pending_merges(user)

    socket = assign(socket, :pending_merges, merges)

    {:noreply, socket}
  end

  # pulls the id off the div constructed above
  defp get_id("merge-" <> id), do: String.to_integer(id)

  defp find_dragged(merges, id) do
    Mrgr.Utils.find_item_in_list(merges, id)
  end

  defp update_merge_order(merges, updated_item, new_index) do
    Mrgr.MergeQueue.update(merges, updated_item, new_index)
  end

  # event bus
  def subscribe(user) do
    topic = Mrgr.PubSub.Topic.installation(user.current_installation)
    Mrgr.PubSub.subscribe(topic)
  end

  # repoened will put it at the top, which may not be what we want
  def handle_info(%{event: event, payload: payload}, socket)
      when event in ["merge:created", "merge:reopened"] do
    merges = socket.assigns.pending_merges

    socket
    |> assign(:pending_merges, [payload | merges])
    |> noreply()
  end

  def handle_info(%{event: "merge:closed", payload: payload}, socket) do
    merges = Enum.reject(socket.assigns.pending_merges, &(&1.id == payload.id))

    socket
    |> put_closed_flash_message(payload)
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  def handle_info(%{event: "merge:synchronized", payload: merge}, socket) do
    hydrated = Mrgr.Merge.preload_for_pending_list(merge)
    merges = replace_updated(socket.assigns.pending_merges, hydrated)

    previously_selected = find_previously_selected(merges, socket.assigns.selected_merge)

    socket
    |> put_flash(
      :info,
      "Open PR \"#{merge.title}\" updated with commit \"#{Mrgr.Schema.Merge.head_commit_message(merge)}\"."
    )
    |> assign(:pending_merges, merges)
    |> assign(:selected_merge, previously_selected)
    |> noreply()
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = merge) do
    put_flash(socket, :warn, "#{merge.title} closed, but not merged")
  end

  defp put_closed_flash_message(socket, merge) do
    put_flash(socket, :info, "#{merge.title} merged! 🍾")
  end

  def replace_updated(merges, updated) do
    updated_id = updated.id

    Enum.map(merges, fn merge ->
      case merge do
        %{id: ^updated_id} ->
          updated

        not_updated ->
          not_updated
      end
    end)
  end

  def find_previously_selected(_merges, nil), do: nil
  def find_previously_selected(merges, merge), do: Mrgr.Utils.find_item_in_list(merges, merge)

  def frozen_repos(repos) do
    Enum.filter(repos, & &1.merge_freeze_enabled)
  end

  # look up the repo in hte socket assigns cause those are the ones who have their
  # merge_freeze_enabled attribute updated
  def repo_text_color(repos, r) do
    case Mrgr.Utils.find_item_in_list(repos, r) do
      %{merge_freeze_enabled: true} -> "text-blue-600"
      %{merge_freeze_enabled: false} -> "text-gray-500"
    end
  end
end
