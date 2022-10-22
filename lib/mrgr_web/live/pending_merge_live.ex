defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      {snoozed, merges} = fetch_pending_merges(current_user) |> partition_snoozed_merges()
      repos = Mrgr.Repository.for_user_with_rules(current_user)
      frozen_repos = filter_frozen_repos(repos)
      subscribe(current_user)

      # id will be `nil` for the index action
      # but present for the show action
      selected_merge = Mrgr.List.find(merges, params["id"])

      socket
      |> assign(:merges, merges)
      |> assign(:snoozed, snoozed)
      |> assign(:selected_merge, selected_merge)
      |> assign(:repos, repos)
      |> assign(:frozen_repos, frozen_repos)
      |> put_title("Pending Merges")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("toggle-merge-freeze", %{"repo-id" => id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, id)

    updated = Mrgr.Repository.toggle_merge_freeze(repo)

    updated_list = Mrgr.List.replace(socket.assigns.repos, updated)
    frozen_repos = filter_frozen_repos(updated_list)

    socket
    |> assign(:repos, updated_list)
    |> assign(:frozen_repos, frozen_repos)
    |> noreply()
  end

  def handle_event("close-detail", _params, socket) do
    socket
    |> assign(:selected_merge, nil)
    |> noreply()
  end

  def handle_event("dropped", %{"draggedId" => id, "draggableIndex" => index}, socket) do
    dragged = find_dragged(socket.assigns.merges, get_id(id))

    merges =
      socket.assigns.merges
      |> update_merge_order(dragged, index)

    socket
    |> assign(:merges, merges)
    |> noreply()
  end

  def handle_event("show-preview", %{"merge-id" => id}, socket) do
    selected =
      Mrgr.List.find(socket.assigns.merges, id) || Mrgr.List.find(socket.assigns.snoozed, id)

    socket
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user

    installation = Mrgr.Repo.preload(user.current_installation, :repositories)
    Mrgr.Installation.refresh_merges!(installation)

    merges = fetch_pending_merges(user)

    socket = assign(socket, :merges, merges)

    {:noreply, socket}
  end

  def handle_event("toggle-check", %{"check-id" => id}, socket) do
    # this will be here since that's how the detail page gets opened
    # should eventually have this state live somewhere else
    checklist = socket.assigns.selected_merge.checklist

    check = Mrgr.List.find(checklist.checks, id)

    updated = Mrgr.Check.toggle(check, socket.assigns.current_user)

    updated_checks = Mrgr.List.replace(checklist.checks, updated)

    updated_checklist = %{checklist | checks: updated_checks}

    merge = %{socket.assigns.selected_merge | checklist: updated_checklist}

    Mrgr.PubSub.broadcast(merge, installation_topic(socket.assigns.current_user), @merge_edited)

    socket
    |> assign(:selected_merge, merge)
    |> noreply
  end

  def handle_event("show-snoozed-merges", _params, socket) do
    merges =
      (socket.assigns.snoozed ++ socket.assigns.merges) |> Enum.sort_by(& &1.merge_queue_index)

    socket
    |> assign(:merges, merges)
    |> noreply()
  end

  def handle_event("snooze-merge", %{"id" => id, "time" => time}, socket) do
    merges = socket.assigns.merges

    updated =
      merges
      |> Mrgr.List.find(id)
      |> Mrgr.Merge.snooze(translate_snooze(time))

    merges = Mrgr.List.remove(merges, updated)
    snoozed = Mrgr.List.add(socket.assigns.snoozed, updated)

    selected =
      case previewing_merge?(socket.assigns.selected_merge, updated) do
        true -> updated
        false -> nil
      end

    socket
    |> assign(:merges, merges)
    |> assign(:snoozed, snoozed)
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  def handle_event("unsnooze-merge", %{"id" => id}, socket) do
    snoozed = socket.assigns.snoozed

    updated =
      snoozed
      |> Mrgr.List.find(id)
      |> Mrgr.Merge.unsnooze()

    snoozed = Mrgr.List.remove(snoozed, updated)
    merges = Mrgr.List.replace!(socket.assigns.merges, updated)

    selected =
      case previewing_merge?(socket.assigns.selected_merge, updated) do
        true -> updated
        false -> nil
      end

    socket
    |> assign(:merges, merges)
    |> assign(:snoozed, snoozed)
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  # pulls the id off the div constructed above
  defp get_id("merge-" <> id), do: String.to_integer(id)

  defp find_dragged(merges, id) do
    Mrgr.List.find(merges, id)
  end

  defp update_merge_order(merges, updated_item, new_index) do
    Mrgr.MergeQueue.update(merges, updated_item, new_index)
  end

  # event bus
  def subscribe(user) do
    user
    |> installation_topic()
    |> Mrgr.PubSub.subscribe()
  end

  def installation_topic(user) do
    Mrgr.PubSub.Topic.installation(user)
  end

  # repoened will put it at the top, which may not be what we want
  def handle_info(%{event: event, payload: payload}, socket)
      when event in [@merge_created, @merge_reopened] do
    merges = socket.assigns.merges

    socket
    |> assign(:merges, [payload | merges])
    |> noreply()
  end

  def handle_info(%{event: @merge_closed, payload: payload}, socket) do
    merges = Mrgr.List.remove(socket.assigns.merges, payload.id)

    selected =
      case previewing_merge?(socket.assigns.selected_merge, payload) do
        true -> nil
        false -> socket.assigns.selected_merge
      end

    socket
    |> put_closed_flash_message(payload)
    |> assign(:merges, merges)
    |> assign(:selected_merge, selected)
    |> noreply()
  end

  def handle_info(%{event: event, payload: merge}, socket)
      when event in [
             @merge_edited,
             @merge_synchronized,
             @merge_comment_created,
             @merge_reviewers_updated,
             @merge_assignees_updated
           ] do
    hydrated = Mrgr.Merge.preload_for_pending_list(merge)
    merges = Mrgr.List.replace(socket.assigns.merges, hydrated)

    previously_selected = find_previously_selected(merges, socket.assigns.selected_merge)

    socket
    |> Flash.put(
      :info,
      "Open PR \"#{merge.title}\" updated with commit \"#{Mrgr.Schema.Merge.head_commit_message(merge)}\"."
    )
    |> assign(:merges, merges)
    |> assign(:selected_merge, previously_selected)
    |> noreply()
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = merge) do
    Flash.put(socket, :warn, "#{merge.title} closed, but not merged")
  end

  defp put_closed_flash_message(socket, merge) do
    Flash.put(socket, :info, "#{merge.title} merged! 🍾")
  end

  def find_previously_selected(_merges, nil), do: nil
  def find_previously_selected(merges, merge), do: Mrgr.List.find(merges, merge)

  defp previewing_merge?(%{id: id}, %{id: id}), do: true
  defp previewing_merge?(_previewing, _closed), do: false

  def filter_frozen_repos(repos) do
    Enum.filter(repos, & &1.merge_freeze_enabled)
  end

  # look up the repo in hte socket assigns cause those are the ones who have their
  # merge_freeze_enabled attribute updated
  defp merge_frozen?(repos, merge) do
    Mrgr.List.member?(repos, merge.repository)
  end

  defp fetch_pending_merges(%{current_installation_id: nil}), do: []

  defp fetch_pending_merges(user) do
    Mrgr.Merge.pending_merges(user)
  end

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_merge, _selected), do: false

  defp translate_snooze("2") do
    Mrgr.DateTime.now() |> DateTime.add(2, :day)
  end

  defp translate_snooze("5") do
    Mrgr.DateTime.now() |> DateTime.add(5, :day)
  end

  defp translate_snooze("indefinitely") do
    # 10 years
    Mrgr.DateTime.now() |> DateTime.add(3650, :day)
  end

  defp partition_snoozed_merges(merges) do
    Enum.split_with(merges, &Mrgr.Merge.snoozed?/1)
  end
end
