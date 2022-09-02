defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

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
      when event in [@merge_created, @merge_reopened] do
    merges = socket.assigns.pending_merges

    socket
    |> assign(:pending_merges, [payload | merges])
    |> noreply()
  end

  def handle_info(%{event: @merge_closed, payload: payload}, socket) do
    merges = Enum.reject(socket.assigns.pending_merges, &(&1.id == payload.id))

    selected =
      case previewing_closed_merge?(socket.assigns.selected_merge, payload) do
        true -> nil
        false -> socket.assigns.selected_merge
      end

    socket
    |> put_closed_flash_message(payload)
    |> assign(:pending_merges, merges)
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  def handle_info(%{event: event, payload: merge}, socket)
      when event in [@merge_edited, @merge_synchronized] do
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

  defp previewing_closed_merge?(%{id: id}, %{id: id}), do: true
  defp previewing_closed_merge?(_previewing, _closed), do: false

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
