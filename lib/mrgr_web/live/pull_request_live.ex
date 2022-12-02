defmodule MrgrWeb.PullRequestLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  alias __MODULE__.Tabs

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      tabs = Tabs.new(current_user)

      repos = Mrgr.Repository.for_user_with_rules(current_user)
      frozen_repos = filter_frozen_repos(repos)
      subscribe(current_user)

      # id will be `nil` for the index action
      # but present for the show action
      # selected_pull_request = Mrgr.List.find(pull_requests, params["id"])
      # not sure how to do this anymore

      socket
      |> assign(:tabs, tabs)
      |> assign(:selected_tab, hd(tabs))
      |> assign(:selected_pull_request, nil)
      |> assign(:repos, repos)
      |> assign(:frozen_repos, frozen_repos)
      |> put_title("Open Pull Requests")
      |> ok()
    else
      ok(socket)
    end
  end

  def handle_event("nav", params, socket) do
    {tabs, selected_tab} = Tabs.nav(params, socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_event("select-tab", %{"id" => id}, socket) do
    selected = Tabs.select(id, socket)

    socket
    |> assign(:selected_tab, selected)
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

  def handle_event("select-pull-request", %{"id" => id}, socket) do
    selected = Tabs.select_pull_request(socket.assigns.selected_tab, id)

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

  def handle_event("toggle-viewing-snoozed", _params, socket) do
    {tabs, selected_tab} = Tabs.toggle_snoozed(socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_event("snooze-pull-request", %{"id" => id, "time" => time}, socket) do
    pull_request = Tabs.select_pull_request(socket.assigns.selected_tab, id)

    Mrgr.PullRequest.snooze(pull_request, translate_snooze(time))

    {tabs, selected} =
      Tabs.reload_prs(
        socket.assigns.tabs,
        socket.assigns.selected_tab,
        socket.assigns.current_user
      )

    socket =
      case previewing_pull_request?(socket.assigns.selected_pull_request, pull_request) do
        true ->
          hide_detail(socket)

        false ->
          socket
      end

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("unsnooze-pull-request", %{"id" => id}, socket) do
    pull_request = Tabs.select_pull_request(socket.assigns.selected_tab, id)

    pull_request = Mrgr.PullRequest.unsnooze(pull_request)

    {tabs, selected} =
      Tabs.reload_prs(
        socket.assigns.tabs,
        socket.assigns.selected_tab,
        socket.assigns.current_user
      )

    # update in place to reflect new status
    socket =
      case previewing_pull_request?(socket.assigns.selected_pull_request, pull_request) do
        true ->
          assign(socket, :selected_pull_request, pull_request)

        false ->
          socket
      end

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
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
             @pull_request_reviews_updated,
             @pull_request_labels_updated
           ] do
    hydrated = Mrgr.PullRequest.preload_for_pending_list(pull_request)

    {tabs, selected_tab} =
      Tabs.update_pr(socket.assigns.tabs, socket.assigns.selected_tab, hydrated)

    selected_pull_request =
      maybe_update_selected_pr(hydrated, socket.assigns.selected_pull_request)

    socket
    |> Flash.put(:info, "Pull Request \"#{pull_request.title}\" updated.")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> assign(:selected_pull_request, selected_pull_request)
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

  def maybe_update_selected_pr(%{id: id} = updated, %{id: id} = _currently_selected), do: updated

  def maybe_update_selected_pr(_pr, currently_selected), do: currently_selected

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

  def pull_requests(selected) do
    Tabs.get_page(selected)
  end

  defmodule Tabs do
    def new(user) do
      [
        %{
          id: "this-week",
          title: "This Week",
          viewing_snoozed: false,
          unsnoozed: load_pull_requests("this-week", user, %{snoozed: false}),
          snoozed: load_pull_requests("this-week", user, %{snoozed: true})
        },
        %{
          id: "last-week",
          title: "Last Week",
          viewing_snoozed: false,
          unsnoozed: load_pull_requests("last-week", user, %{snoozed: false}),
          snoozed: load_pull_requests("last-week", user, %{snoozed: true})
        },
        %{
          id: "this-month",
          title: "This Month",
          viewing_snoozed: false,
          unsnoozed: load_pull_requests("this-month", user, %{snoozed: false}),
          snoozed: load_pull_requests("this-month", user, %{snoozed: true})
        },
        %{
          id: "stale",
          title: "Stale (> 4 weeks)",
          viewing_snoozed: false,
          unsnoozed: load_pull_requests("stale", user, %{snoozed: false}),
          snoozed: load_pull_requests("stale", user, %{snoozed: true})
        }
      ]
    end

    def update_pr(tabs, selected, pr) do
      # slow, dumb traversal through everything.  ignore snoozed stuff
      tabs =
        Enum.map(tabs, fn tab ->
          unsnoozed = Mrgr.List.replace(tab.unsnoozed, pr)
          %{tab | unsnoozed: unsnoozed}
        end)

      selected = %{selected | unsnoozed: Mrgr.List.replace(selected.unsnoozed, pr)}

      {tabs, selected}
    end

    def reload_prs(all, selected, user) do
      {snoozed, unsnoozed} = load_prs(selected, user)
      updated = %{selected | snoozed: snoozed, unsnoozed: unsnoozed}

      {Mrgr.List.replace(all, updated), updated}
    end

    def nav(params, %{assigns: %{tabs: tabs, selected_tab: selected_tab, current_user: user}}) do
      params = Map.merge(params, %{snoozed: selected_tab.viewing_snoozed})

      page = load_pull_requests(selected_tab.id, user, params)

      tabs = set_page(tabs, selected_tab, page)

      selected = select(tabs, selected_tab.id)

      {tabs, selected}
    end

    def select(id, %{assigns: %{tabs: tabs}}) do
      select(tabs, id)
    end

    def select(tabs, id) do
      Enum.find(tabs, fn i -> i.id == id end)
    end

    def select_pull_request(tab, id) do
      tab
      |> viewing_page()
      |> Map.get(:entries)
      |> select(id)
    end

    def viewing_page(tab) do
      case tab.viewing_snoozed do
        true -> tab.snoozed
        false -> tab.unsnoozed
      end
    end

    def load_prs(tab, user) do
      snoozed =
        load_pull_requests(tab.id, user, %{snoozed: true, page_number: tab.snoozed.page_number})

      unsnoozed =
        load_pull_requests(tab.id, user, %{snoozed: false, page_number: tab.unsnoozed.page_number})

      {snoozed, unsnoozed}
    end

    def load_pull_requests(key, user, page_params \\ %{})

    def load_pull_requests("this-week", user, page_params) do
      opts = Map.merge(page_params, %{since: this_week()})

      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def load_pull_requests("last-week", user, page_params) do
      opts = Map.merge(page_params, %{before: this_week(), since: two_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def load_pull_requests("this-month", user, page_params) do
      opts = Map.merge(page_params, %{before: two_weeks_ago(), since: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def load_pull_requests("stale", user, page_params) do
      opts = Map.merge(page_params, %{before: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(user, opts)
    end

    def set_page(all, selected, page) do
      updated =
        case selected.viewing_snoozed do
          true -> Map.put(selected, :snoozed, page)
          false -> Map.put(selected, :unsnoozed, page)
        end

      Mrgr.List.replace(all, updated)
    end

    def toggle_snoozed(%{assigns: %{tabs: tabs, selected_tab: tab}}) do
      tab = toggle_snoozed(tab)
      tabs = Mrgr.List.replace(tabs, tab)
      {tabs, tab}
    end

    def toggle_snoozed(%{viewing_snoozed: true} = tab), do: %{tab | viewing_snoozed: false}
    def toggle_snoozed(%{viewing_snoozed: false} = tab), do: %{tab | viewing_snoozed: true}

    def get_page(%{viewing_snoozed: true, snoozed: prs}), do: prs
    def get_page(%{viewing_snoozed: false, unsnoozed: prs}), do: prs

    defp this_week do
      # last 7 days
      Mrgr.DateTime.shift_from_now(-7, :day)
    end

    defp two_weeks_ago do
      Mrgr.DateTime.shift_from_now(-14, :day)
    end

    defp four_weeks_ago do
      Mrgr.DateTime.shift_from_now(-28, :day)
    end
  end
end
