defmodule MrgrWeb.PullRequestLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest
  alias __MODULE__.Tabs

  on_mount MrgrWeb.Plug.Auth

  def mount(params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      {snoozed, pull_requests} = {[], []}
      # fetch_pending_pull_requests(current_user) |> partition_snoozed_pull_requests()

      tabs = Tabs.new(current_user)

      repos = Mrgr.Repository.for_user_with_rules(current_user)
      frozen_repos = filter_frozen_repos(repos)
      subscribe(current_user)

      # id will be `nil` for the index action
      # but present for the show action
      selected_pull_request = Mrgr.List.find(pull_requests, params["id"])

      socket
      |> assign(:tabs, tabs)
      |> assign(:selected_tab, hd(tabs))
      |> assign(:pull_requests, Map.get(hd(tabs), :prs))
      |> assign(:snoozed, snoozed)
      |> assign(:selected_pull_request, selected_pull_request)
      |> assign(:repos, repos)
      |> assign(:frozen_repos, frozen_repos)
      |> put_title("Open Pull Requests")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("nav", params, socket) do
    {tabs, page} = Tabs.nav(params, socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:pull_requests, page)
    |> noreply()
  end

  def handle_event("select-tab", %{"name" => name}, socket) do
    {tabs, selected_prs} = Tabs.select(name, socket)

    socket
    |> assign(:selected_tab, name)
    |> assign(:tabs, tabs)
    |> assign(:pull_requests, selected_prs)
    |> noreply()
  end

  def handle_event("toggle-merge-freeze", %{"repo-id" => id}, socket) do
    repo = Mrgr.List.find(socket.assigns.repos, id)

    updated = Mrgr.Repository.toggle_pull_request_freeze(repo)

    updated_list = Mrgr.List.replace(socket.assigns.repos, updated)
    frozen_repos = filter_frozen_repos(updated_list)

    socket
    |> assign(:repos, updated_list)
    |> assign(:frozen_repos, frozen_repos)
    |> noreply()
  end

  def handle_event("dropped", %{"draggedId" => id, "draggableIndex" => index}, socket) do
    dragged = find_dragged(socket.assigns.pull_requests, get_id(id))

    pull_requests =
      socket.assigns.pull_requests
      |> update_pull_request_order(dragged, index)

    socket
    |> assign(:pull_requests, pull_requests)
    |> noreply()
  end

  def handle_event("select-pull-request", %{"pull-request-id" => id}, socket) do
    selected =
      Mrgr.List.find(socket.assigns.pull_requests, id) ||
        Mrgr.List.find(socket.assigns.snoozed, id)

    socket
    |> assign(:selected_pull_request, selected)
    |> noreply()
  end

  def handle_event("unselect-pull-request", _params, socket) do
    socket
    |> assign(:selected_pull_request, nil)
    |> noreply()
  end

  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user

    installation = Mrgr.Repo.preload(user.current_installation, :repositories)
    Mrgr.Installation.refresh_pull_requests!(installation)

    pull_requests = fetch_pending_pull_requests(user)

    socket = assign(socket, :pull_requests, pull_requests)

    {:noreply, socket}
  end

  def handle_event("toggle-check", %{"check-id" => id}, socket) do
    # this will be here since that's how the detail page gets opened
    # should eventually have this state live somewhere else
    checklist = socket.assigns.selected_pull_request.checklist

    check = Mrgr.List.find(checklist.checks, id)

    updated = Mrgr.Check.toggle(check, socket.assigns.current_user)

    updated_checks = Mrgr.List.replace(checklist.checks, updated)

    updated_checklist = %{checklist | checks: updated_checks}

    pull_request = %{socket.assigns.selected_pull_request | checklist: updated_checklist}

    Mrgr.PubSub.broadcast(
      pull_request,
      installation_topic(socket.assigns.current_user),
      @pull_request_edited
    )

    socket
    |> assign(:selected_pull_request, pull_request)
    |> noreply
  end

  def handle_event("show-snoozed-pull-requests", _params, socket) do
    pull_requests =
      (socket.assigns.snoozed ++ socket.assigns.pull_requests)
      |> Enum.sort_by(& &1.merge_queue_index)

    socket
    |> assign(:pull_requests, pull_requests)
    |> noreply()
  end

  def handle_event("snooze-pull-request", %{"id" => id, "time" => time}, socket) do
    pull_requests = socket.assigns.pull_requests

    updated =
      pull_requests
      |> Mrgr.List.find(id)
      |> Mrgr.PullRequest.snooze(translate_snooze(time))

    pull_requests = Mrgr.List.remove(pull_requests, updated)
    snoozed = Mrgr.List.add(socket.assigns.snoozed, updated)

    socket =
      case previewing_pull_request?(socket.assigns.selected_pull_request, updated) do
        true ->
          hide_detail(socket)

        false ->
          socket
      end

    socket
    |> assign(:pull_requests, pull_requests)
    |> assign(:snoozed, snoozed)
    |> noreply()
  end

  def handle_event("unsnooze-pull-request", %{"id" => id}, socket) do
    snoozed = socket.assigns.snoozed

    updated =
      snoozed
      |> Mrgr.List.find(id)
      |> Mrgr.PullRequest.unsnooze()

    snoozed = Mrgr.List.remove(snoozed, updated)
    pull_requests = Mrgr.List.replace!(socket.assigns.pull_requests, updated)

    socket
    |> assign(:pull_requests, pull_requests)
    |> assign(:snoozed, snoozed)
    |> noreply()
  end

  # pulls the id off the div constructed above
  defp get_id("pull-request-" <> id), do: String.to_integer(id)

  defp find_dragged(pull_requests, id) do
    Mrgr.List.find(pull_requests, id)
  end

  defp update_pull_request_order(pull_requests, updated_item, new_index) do
    Mrgr.MergeQueue.update(pull_requests, updated_item, new_index)
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
      when event in [@pull_request_created, @pull_request_reopened] do
    pull_requests = socket.assigns.pull_requests

    socket
    |> assign(:pull_requests, [payload | pull_requests])
    |> noreply()
  end

  def handle_info(%{event: @pull_request_closed, payload: payload}, socket) do
    pull_requests = Mrgr.List.remove(socket.assigns.pull_requests, payload.id)

    socket
    |> put_closed_flash_message(payload)
    |> assign(:pull_requests, pull_requests)
    |> noreply()
  end

  def handle_info(%{event: event, payload: pull_request}, socket)
      when event in [
             @pull_request_edited,
             @pull_request_synchronized,
             @pull_request_comment_created,
             @pull_request_reviewers_updated,
             @pull_request_assignees_updated,
             @pull_request_reviews_updated
           ] do
    hydrated = Mrgr.PullRequest.preload_for_pending_list(pull_request)
    pull_requests = Mrgr.List.replace(socket.assigns.pull_requests, hydrated)

    previously_selected =
      find_previously_selected(pull_requests, socket.assigns.selected_pull_request)

    socket
    |> Flash.put(:info, "Pull Request \"#{pull_request.title}\" updated.")
    |> assign(:pull_requests, pull_requests)
    |> assign(:selected_pull_request, previously_selected)
    |> noreply()
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  def snooze_options do
    [
      %{title: "2 Days", value: "2"},
      %{title: "5 Days", value: "5"},
      %{title: "Indefinitely", value: "indefinitely"}
    ]
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = pull_request) do
    Flash.put(socket, :warn, "#{pull_request.title} closed, but not merged")
  end

  defp put_closed_flash_message(socket, pull_request) do
    Flash.put(socket, :info, "#{pull_request.title} merged! 🍾")
  end

  def find_previously_selected(_pull_requests, nil), do: nil

  def find_previously_selected(pull_requests, pull_request),
    do: Mrgr.List.find(pull_requests, pull_request)

  defp previewing_pull_request?(%{id: id}, %{id: id}), do: true
  defp previewing_pull_request?(_previewing, _closed), do: false

  def filter_frozen_repos(repos) do
    Enum.filter(repos, & &1.merge_freeze_enabled)
  end

  # look up the repo in hte socket assigns cause those are the ones who have their
  # merge_freeze_enabled attribute updated
  defp merge_frozen?(repos, pull_request) do
    Mrgr.List.member?(repos, pull_request.repository)
  end

  defp fetch_pending_pull_requests(%{current_installation_id: nil}), do: []

  defp fetch_pending_pull_requests(user) do
    Mrgr.PullRequest.pending_pull_requests(user)
  end

  defp selected?(%{id: id}, %{id: id}), do: true
  defp selected?(_pull_request, _selected), do: false

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

  defp partition_snoozed_pull_requests(pull_requests) do
    Enum.split_with(pull_requests, &Mrgr.PullRequest.snoozed?/1)
  end

  defmodule Tabs do
    def new(user) do
      [
        %{
          id: "recently-opened",
          title: "Recent",
          prs: load_pull_requests("recently-opened", user)
        },
        %{id: "socks", title: "Socks", prs: load_pull_requests("socks", user)},
        %{id: "stale", title: "Stale", prs: load_pull_requests("stale", user)}
      ]
    end

    def nav(params, %{assigns: %{tabs: tabs, selected_tab: selected_tab, current_user: user}}) do
      page = load_pull_requests(selected_tab, user, params)

      tabs = set_page(tabs, selected_tab, page)

      {tabs, page}
    end

    def select(name, %{assigns: %{tabs: tabs, current_user: user}}) do
      select_pull_requests(tabs, name, user)
    end

    def select_pull_requests(tabs, name, user) do
      item = Enum.find(tabs, fn i -> i.id == name end)

      case item.prs do
        :not_loaded ->
          prs = load_pull_requests(name, user)

          new_item = Map.put(item, :prs, prs)
          tabs = Mrgr.List.replace(tabs, new_item)

          {tabs, prs}

        prs ->
          {tabs, prs}
      end
    end

    def load_pull_requests(key, user, page_params \\ %{})

    def load_pull_requests("recently-opened", user, page_params) do
      opts = Map.merge(page_params, %{since: two_weeks_ago()})

      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def load_pull_requests("socks", user, page_params) do
      opts = Map.merge(page_params, %{before: two_weeks_ago(), since: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def load_pull_requests("stale", user, page_params) do
      opts = Map.merge(page_params, %{before: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def set_page(all, id, page) do
      item = Enum.find(all, fn i -> i.id == id end)

      new_item = Map.put(item, :prs, page)
      all = Mrgr.List.replace(all, new_item)
    end

    defp two_weeks_ago do
      Mrgr.DateTime.shift_from_now(-14, :day)
    end

    defp four_weeks_ago do
      Mrgr.DateTime.shift_from_now(-28, :day)
    end
  end
end
