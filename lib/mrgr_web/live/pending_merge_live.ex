defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      merges = Mrgr.Merge.pending_merges(current_user)
      subscribe(current_user)

      socket
      |> assign(:current_user, current_user)
      |> assign(:pending_merges, merges)
      |> assign(:selected_merge, nil)
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:pending_merges, [])
      |> assign(:selected_merge, nil)
      |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <.heading title="Pending Merges" />

      <div class="flex mt-8 space-x-4">
        <div class="basis-1/2 bg-white px-2 py-5 sm:px-6 overflow-hidden shadow rounded-lg">

          <div class="shadow overflow-hidden sm:rounded-md" phx-hook="Drag" id="drag">

            <ul role="list" class="divide-y divide-gray-200 dropzone" id="pending-merge-list">
              <%= for merge <- assigns.pending_merges do %>
                <li draggable="true" class="draggable merge-list" id={"merge-#{merge.id}"}>
                  <div class="block hover:bg-gray-50">
                    <div class="px-4 py-4 sm:px-6">
                      <div class="flex items-center justify-between">
                        <%= link merge.title, to: "#", phx_click: "show_preview", phx_value_merge_id: merge.id, class: "text-sm font-medium text-teal-500 truncate" %>
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
                          <p class="flex items-center text-sm text-gray-500">
                            <!-- Heroicon name: solid/users -->
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                              <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z" />
                            </svg>
                            <%= merge.repository.name %>
                          </p>
                          <p class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                            <!-- Heroicon name: solid/location-marker -->
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                              <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                            </svg>
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
            </ul>

          </div>
        </div>

        <.live_component module={MrgrWeb.Components.Live.MergePreviewComponent} id="merge_preview" merge={@selected_merge} current_user={@current_user} />
      </div>
    </div>
    <.button phx-click="refresh"> Refresh PRs</.button>

    """
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
    id = String.to_integer(id)

    selected = find_from_merges(socket.assigns.pending_merges, id)

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
    Mrgr.MergeQueue.find_merge_by_id(merges, id)
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
  def find_previously_selected(merges, %{id: id}), do: find_from_merges(merges, id)

  defp find_from_merges(merges, id) do
    Enum.find(merges, fn m -> m.id == id end)
  end
end
