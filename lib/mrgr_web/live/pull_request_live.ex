defmodule MrgrWeb.PullRequestLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  alias __MODULE__.Tabs

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      repos = Mrgr.Repository.for_user_with_rules(current_user)
      frozen_repos = filter_frozen_repos(repos)

      labels = Mrgr.Label.list_for_user(current_user)
      members = Mrgr.Repo.all(Mrgr.Member.for_installation(current_user.current_installation_id))

      tabs = Tabs.new(current_user)

      snooze_options = snooze_options()

      subscribe(current_user)

      IO.inspect("MOUNT")

      socket
      |> assign(:tabs, tabs)
      |> assign(:repos, repos)
      |> assign(:labels, labels)
      |> assign(:members, members)
      |> assign(:snooze_options, snooze_options)
      |> assign(:frozen_repos, frozen_repos)
      |> put_title("Open Pull Requests")
      |> ok()
    else
      IO.inspect("MOUNT - DIS CONNECTED")

      socket
      |> assign(:detail, nil)
      |> assign(:selected_attr, nil)
      |> ok()

      # ok(socket)
    end
  end

  # index action
  def handle_params(params, uri, socket) when params == %{} do
    if connected?(socket) do
      IO.inspect("HANDLE PARAMS - CONNECTED")

      socket
      |> assign(:selected_tab, hd(socket.assigns.tabs))
      |> assign(:detail, nil)
      |> assign(:selected_attr, nil)
      |> noreply()
    else
      IO.inspect("HANDLE PARAMS - DIS CONNECTED")

      socket
      # |> assign(:detail, nil)
      # |> assign(:selected_attr, nil)
      |> noreply()
    end
  end

  def handle_params(%{"tab" => id}, uri, socket) do
    if connected?(socket) do
      IO.inspect("HANDLE PARAMS - CONNECTED")

      id = case Integer.parse(id) do
        :error -> id # permalink-type
        {id, _} -> id # numeric
      end

      selected = get_tab(socket.assigns.tabs, id)

      socket
      |> assign(:selected_tab, selected)
      |> assign(:detail, nil)
      |> assign(:selected_attr, nil)
      |> noreply()
    else
      IO.inspect("HANDLE PARAMS - DIS CONNECTED")

      socket
      # |> assign(:detail, nil)
      # |> assign(:selected_attr, nil)
      |> noreply()
    end
  end

  def handle_event("paginate", params, socket) do
    {tabs, selected_tab} = Tabs.paginate(params, socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_event("add-tab", _params, socket) do
    {tabs, new_tab} = Tabs.add(socket.assigns.tabs, socket.assigns.current_user)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, new_tab)
    |> noreply()
  end

  def handle_event("delete-tab", _params, socket) do
    goner = socket.assigns.selected_tab

    {tabs, newly_selected} = Tabs.delete(socket.assigns.tabs, goner)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, newly_selected)
    |> assign(:detail, nil)
    |> hide_detail()
    |> noreply()
  end

  def handle_event("cancel-tab-edit", _params, socket) do
    tabs = Tabs.stop_editing(socket.assigns.tabs, socket.assigns.selected_tab.id)
    selected = get_selected_tab(tabs, socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("save-tab", %{"tab" => params}, socket) do
    {tabs, updated_tab} = Tabs.update(socket.assigns.tabs, socket.assigns.selected_tab, params)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, updated_tab)
    |> noreply()
  end

  def handle_event("edit-tab", %{"id" => id}, socket) do
    tabs = Tabs.edit(socket.assigns.tabs, id)
    selected = get_selected_tab(tabs, socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("toggle-author", %{"id" => id}, socket) do
    author = Mrgr.List.find(socket.assigns.members, id)
    selected_tab = socket.assigns.selected_tab

    updated_tab = Mrgr.PRTab.toggle_author(selected_tab, author)

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, updated_tab)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("toggle-label", %{"id" => id}, socket) do
    label = Mrgr.List.find(socket.assigns.labels, id)
    selected_tab = socket.assigns.selected_tab

    updated_tab = Mrgr.PRTab.toggle_label(selected_tab, label)

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, updated_tab)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("toggle-repository", %{"id" => id}, socket) do
    repository = Mrgr.List.find(socket.assigns.repos, id)
    selected_tab = socket.assigns.selected_tab

    updated_tab = Mrgr.PRTab.toggle_repository(selected_tab, repository)

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, updated_tab)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event(
        "toggle-reviewer",
        %{"id" => member_id, "pull_request_id" => pull_request_id},
        socket
      ) do
    reviewer = Mrgr.List.find(socket.assigns.members, member_id)
    pull_request = Tabs.find_pull_request(socket.assigns.selected_tab, pull_request_id)

    Task.start(fn ->
      Mrgr.PullRequest.toggle_reviewer(pull_request, reviewer)
    end)

    socket
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

  def handle_event("snooze", %{"snooze_id" => snooze_id, "pr_id" => pull_request_id}, socket) do
    selected_tab = socket.assigns.selected_tab

    pull_request =
      selected_tab
      |> Tabs.find_pull_request(pull_request_id)
      |> Mrgr.PullRequest.snooze(translate_snooze(snooze_id))

    tabs = Tabs.snooze(socket.assigns.tabs, selected_tab, pull_request)
    selected = get_selected_tab(tabs, socket)

    socket =
      case previewing_pull_request?(socket.assigns.detail, pull_request) do
        true ->
          hide_detail(socket)

        false ->
          socket
      end

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> Flash.put(:info, "PR snoozed 😴")
    |> noreply()
  end

  def handle_event("unsnooze", %{"pr_id" => id}, socket) do
    selected_tab = socket.assigns.selected_tab

    pull_request =
      selected_tab
      |> Tabs.find_pull_request(id)
      |> Mrgr.PullRequest.unsnooze()

    tabs = Tabs.unsnooze(socket.assigns.tabs, pull_request)
    selected = get_selected_tab(tabs, socket)

    # update in place to reflect new status
    socket =
      case previewing_pull_request?(socket.assigns.detail, pull_request) do
        true ->
          assign(socket, :detail, pull_request)

        false ->
          socket
      end

    socket
    |> Flash.put(:info, "PR unsnoozed! ☀️")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("show-detail-" <> attr, %{"id" => id}, socket) do
    pr = Tabs.find_pull_request(socket.assigns.selected_tab, id)

    socket
    |> assign(:detail, pr)
    |> assign(:selected_attr, attr)
    |> show_detail()
    |> noreply()
  end

  def handle_event("hide-detail", _params, socket) do
    socket
    |> assign(:detail, nil)
    |> noreply()
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

  def handle_info(%{event: event, payload: payload}, socket)
      when event in [@pull_request_created, @pull_request_reopened] do
    hydrated = Mrgr.PullRequest.preload_for_pending_list(payload)
    tabs = Tabs.receive_opened_pull_request(socket.assigns.tabs, hydrated)
    selected_tab = get_selected_tab(tabs, socket)

    socket
    |> Flash.put(:info, "PR opened: #{hydrated.title}")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_info(%{event: @pull_request_closed, payload: payload}, socket) do
    tabs = Tabs.remove_pull_request(socket.assigns.tabs, payload)
    selected_tab = get_selected_tab(tabs, socket)

    socket
    |> put_closed_flash_message(payload)
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
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
             @pull_request_labels_updated,
             @pull_request_ci_status_updated
           ] do
    hydrated = Mrgr.PullRequest.preload_for_pending_list(pull_request)

    tabs = Tabs.update_pull_request(socket.assigns.tabs, hydrated)
    selected_tab = get_selected_tab(tabs, socket)

    selected_pull_request = maybe_update_selected_pr(hydrated, socket.assigns.detail)

    socket
    |> Flash.put(:info, "PR updated: #{hydrated.title}")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> assign(:detail, selected_pull_request)
    |> noreply()
  end

  def handle_info({_ref, {:time, elapsed}}, socket) do
    IO.inspect(elapsed, label: "ELAPSED")

    socket
    |> noreply()
  end

  # async data loading
  def handle_info({ref, result}, socket) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])

    tabs = Tabs.set_prs_on_tab_from_async(socket.assigns.tabs, ref, result)
    selected_tab = Tabs.set_prs_on_tab_from_async(socket.assigns.selected_tab, ref, result)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  # If the task fails...
  def handle_info({:DOWN, _ref, _, _, reason}, socket) do
    IO.puts("failed with reason #{inspect(reason)}")
    noreply(socket)
  end

  def handle_info(_uninteresting_event, socket) do
    noreply(socket)
  end

  def snooze_options do
    [
      %{name: "2 Days", id: "2-days"},
      %{name: "5 Days", id: "5-days"},
      %{name: "Indefinitely", id: "indefinitely"}
    ]
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = pull_request) do
    Flash.put(socket, :info, "#{pull_request.title} closed, but not merged")
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

  def selected?(%{id: id}, %{id: id}), do: true
  def selected?(_pull_request, _selected), do: false

  def show_action_state_emoji?(%{id: id})
      when id in ["ready-to-merge", "needs-approval", "fix-ci"],
      do: false

  def show_action_state_emoji?(_current_tab), do: true

  defp translate_snooze("2-days") do
    Mrgr.DateTime.now() |> DateTime.add(2, :day)
  end

  defp translate_snooze("5-days") do
    Mrgr.DateTime.now() |> DateTime.add(5, :day)
  end

  defp translate_snooze("indefinitely") do
    # 10 years
    Mrgr.DateTime.now() |> DateTime.add(3650, :day)
  end

  def custom?(tab) do
    Tabs.custom?(tab)
  end

  def get_selected_tab(tabs, socket) do
    get_tab(tabs, socket.assigns.selected_tab.id)
  end

  def get_tab(tabs, tab_id) do
    Tabs.find_tab_by_id(tabs, tab_id)
  end

  def filter_showing(repos) do
    Enum.filter(repos, & &1.show_prs)
  end

  defmodule Tabs do
    @ready_to_merge "ready-to-merge"
    @needs_approval "needs-approval"
    @fix_ci "fix-ci"
    @snoozed "snoozed"
    @hifs "hifs"

    def new(user) do
      []
      |> Kernel.++(system_tabs_for_user(user))
      |> Kernel.++(custom_tabs_for_user(user))
      |> Enum.map(&load_prs_async/1)
    end

    def add(tabs, user) do
      new_tab = Mrgr.PRTab.create(user)
      updated_tabs = tabs ++ [new_tab]

      {updated_tabs, new_tab}
    end

    def edit(tabs, id) do
      tab = find_tab_by_id(tabs, id)
      editing = %{tab | editing: true}

      replace_tabs(tabs, editing)
    end

    def stop_editing(tabs, id) do
      tab = find_tab_by_id(tabs, id)
      editing = %{tab | editing: false}

      replace_tabs(tabs, editing)
    end

    def update(tabs, tab, params) do
      {:ok, updated_tab} = Mrgr.PRTab.update(tab, params)

      updated_tabs = reload_tab(tabs, %{updated_tab | editing: false})

      {updated_tabs, updated_tab}
    end

    # assumes the tab being deleted is currently selected.
    # Select the next tab to the right.
    def delete(tabs, tab) do
      old_idx = Mrgr.List.find_index(tabs, tab)
      updated_tabs = Mrgr.List.remove(tabs, tab)

      Mrgr.PRTab.delete(tab)

      newly_selected =
        case Enum.at(updated_tabs, old_idx) do
          nil -> hd(Enum.reverse(updated_tabs))
          new_guy -> new_guy
        end

      {updated_tabs, newly_selected}
    end

    def reload_tab(tabs, tab) do
      idx = Mrgr.List.find_index(tabs, tab)

      tabs
      |> Mrgr.List.remove(tab)
      |> List.insert_at(idx, tab)
    end

    def system_tabs_for_user(user) do
      [
        %{
          id: @ready_to_merge,
          title: "🚀 Ready to Merge",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @needs_approval,
          title: "⚠️ Needs Approval",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @fix_ci,
          title: "🛠 Fix CI",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @hifs,
          title: "💥 High Impact Changes",
          type: "system",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @snoozed,
          title: "😴 Snoozed",
          type: "system",
          meta: %{user: user},
          pull_requests: []
        }
      ]
    end

    def custom_tabs_for_user(user) do
      Mrgr.PRTab.for_user(user)
    end

    def find_tab_by_ref(tabs, ref) do
      Enum.find(tabs, fn tab -> tab.meta[:ref] == ref end)
    end

    def find_tab_by_id(tabs, id) do
      Enum.find(tabs, fn i -> i.id == id end)
    end

    def system_tabs(tabs) do
      Enum.reject(tabs, &custom?/1)
    end

    def custom_tabs(tabs) do
      Enum.filter(tabs, &custom?/1)
    end

    def custom?(%Mrgr.Schema.PRTab{}), do: true
    def custom?(_), do: false

    def snoozed?(%{id: @snoozed}), do: true
    def snoozed?(_), do: false

    def set_prs_on_tab_from_async(tabs, ref, data) when is_list(tabs) do
      case find_tab_by_ref(tabs, ref) do
        nil ->
          tabs

        tab ->
          updated = set_prs_on_tab_from_async(tab, ref, data)

          replace_tabs(tabs, updated)
      end
    end

    # data for the currently visible tab
    def set_prs_on_tab_from_async(%{meta: %{ref: ref}} = tab, ref, page) do
      meta = Map.drop(tab.meta, [:ref])

      tab
      |> set_prs_on_tab(page)
      |> Map.put(:meta, meta)
    end

    # data for a different tab
    def set_prs_on_tab_from_async(tab, _ref, _data), do: tab

    def update_pull_request(tabs, pr) do
      tabs
      |> update_action_state_tabs(pr)
      # replaces the PR again in the action state tabs, but i don't
      # care about the extra work rn.  this code is simpler than extracting
      # non action state tabs and just replacing it in those.  can optimize laterz
      |> Enum.map(&replace_pr_in_tab(&1, pr))
    end

    def remove_pull_request(tabs, pr) do
      Enum.map(tabs, &excise_pr_from_tab(&1, pr))
    end

    def update_action_state_tabs(tabs, pull_request) do
      # pr may move from eg Fix CI to Ready to Merge

      case Mrgr.PullRequest.action_state(pull_request) do
        :ready_to_merge ->
          tabs
          |> excise_pr_from_tab(@needs_approval, pull_request)
          |> excise_pr_from_tab(@fix_ci, pull_request)
          |> update_or_poke_pr_in_tab(@ready_to_merge, pull_request)

        :needs_approval ->
          tabs
          |> excise_pr_from_tab(@ready_to_merge, pull_request)
          |> excise_pr_from_tab(@fix_ci, pull_request)
          |> update_or_poke_pr_in_tab(@needs_approval, pull_request)

        :fix_ci ->
          tabs
          |> excise_pr_from_tab(@ready_to_merge, pull_request)
          |> excise_pr_from_tab(@needs_approval, pull_request)
          |> update_or_poke_pr_in_tab(@fix_ci, pull_request)
      end
    end

    def receive_opened_pull_request(tabs, pr) do
      needs_approval_tab =
        tabs
        |> find_tab_by_id(@needs_approval)
        |> poke_pr_into_tab(pr)

      refreshing =
        tabs
        |> custom_tabs()
        |> Enum.map(&refresh_tab_async/1)

      replace_tabs(tabs, [needs_approval_tab, refreshing])
    end

    def snooze(tabs, selected, pull_request) do
      # just operate on the main tabs data structure
      updated = excise_pr_from_tab(selected, pull_request)

      snoozed =
        tabs
        |> find_tab_by_id(@snoozed)
        |> poke_pr_into_tab(pull_request)

      replace_tabs(tabs, [updated, snoozed])
    end

    # hard to be smart about poking in the PR to system tabs
    # because the pr may not supposed be on the currently viewed page.
    # also, no good way to ask custom tabs if the PR belongs to them other
    # than just re-running the db query.  so let's just reload everything and KISS.
    # I don't think people will be unsnoozing things very often anyway.
    def unsnooze(tabs, pull_request) do
      tabs
      |> remove_pr_from_snoozed_tab(pull_request)
      |> refresh_non_snoozed_tabs_async()
    end

    def remove_pr_from_snoozed_tab(tabs, pull_request) do
      updated_tab =
        tabs
        |> find_tab_by_id(@snoozed)
        |> excise_pr_from_tab(pull_request)

      replace_tabs(tabs, updated_tab)
    end

    def excise_pr_from_tab(tabs, id, pull_request) when is_list(tabs) do
      updated_tab =
        tabs
        |> find_tab_by_id(id)
        |> excise_pr_from_tab(pull_request)

      replace_tabs(tabs, updated_tab)
    end

    def excise_pr_from_tab(tab, pull_request) do
      # funky stuff

      page = tab.pull_requests

      updated_page = remove_pr_from_page(page, pull_request)

      set_prs_on_tab(tab, updated_page)
    end

    def update_or_poke_pr_in_tab(tabs, id, pull_request) do
      updated_tab =
        tabs
        |> find_tab_by_id(id)
        |> update_or_poke_pr_in_tab(pull_request)

      replace_tabs(tabs, updated_tab)
    end

    def update_or_poke_pr_in_tab(tab, pull_request) do
      case contains_pr?(tab, pull_request) do
        true -> replace_pr_in_tab(tab, pull_request)
        false -> poke_pr_into_tab(tab, pull_request)
      end
    end

    def poke_pr_into_tab(tab, pull_request) do
      # I can't get enough
      # of that funky stuff

      page = tab.pull_requests

      entries = [pull_request | page.entries]
      updated_count = page.total_entries + 1

      updated_page = %{page | total_entries: updated_count, entries: entries}

      set_prs_on_tab(tab, updated_page)
    end

    def replace_pr_in_tab(tab, pull_request) do
      page = replace_pr_in_page(tab.pull_requests, pull_request)
      set_prs_on_tab(tab, page)
    end

    def refresh_non_snoozed_tabs_async(tabs) do
      refreshing =
        tabs
        |> Enum.reject(&snoozed?/1)
        |> Enum.map(&refresh_tab_async/1)

      replace_tabs(tabs, refreshing)
    end

    def refresh_tab_async(tab) do
      # refresh the current page
      opts = %{page_number: safe_page_number(tab.pull_requests)}
      load_prs_async(tab, opts)
    end

    def reload_prs(all, selected) do
      pull_requests =
        fetch_paged_pull_requests(selected, %{
          page_number: safe_page_number(selected.pull_requests)
        })

      updated = set_prs_on_tab(selected, pull_requests)

      {replace_tabs(all, updated), updated}
    end

    def safe_page_number([]), do: 1

    def safe_page_number(page) do
      page.page_number
    end

    def paginate(params, %{assigns: %{tabs: tabs, selected_tab: selected_tab}}) do
      page = fetch_paged_pull_requests(selected_tab, params)

      tabs = set_prs_on_tab(tabs, selected_tab, page)

      selected = find_tab_by_id(tabs, selected_tab.id)

      {tabs, selected}
    end

    def find_pull_request(tab, id) do
      tab.pull_requests
      |> Map.get(:entries)
      |> Mrgr.List.find(id)
    end

    def load_prs_async(tab, opts \\ %{}) do
      task = Task.async(fn -> fetch_paged_pull_requests(tab, opts) end)

      meta = tab.meta

      %{tab | meta: Map.put(meta, :ref, task.ref)}
    end

    def fetch_paged_pull_requests(tab, page_params \\ %{})

    def fetch_paged_pull_requests(%{id: @ready_to_merge} = tab, opts) do
      Mrgr.PullRequest.paged_ready_to_merge_prs(tab.meta.user, opts)
    end

    def fetch_paged_pull_requests(%{id: @needs_approval} = tab, opts) do
      Mrgr.PullRequest.paged_needs_approval_prs(tab.meta.user, opts)
    end

    def fetch_paged_pull_requests(%{id: @fix_ci} = tab, opts) do
      Mrgr.PullRequest.paged_fix_ci_prs(tab.meta.user, opts)
    end

    def fetch_paged_pull_requests(%{id: @hifs} = tab, opts) do
      Mrgr.PullRequest.paged_high_impact_prs(tab.meta.user, opts)
    end

    def fetch_paged_pull_requests(%{id: @snoozed} = tab, opts) do
      Mrgr.PullRequest.paged_snoozed_prs(tab.meta.user, opts)
    end

    def fetch_paged_pull_requests(%Mrgr.Schema.PRTab{} = tab, opts) do
      Mrgr.PullRequest.paged_nav_tab_prs(tab, opts)
    end

    def fetch_paged_pull_requests(_unknown_tab, _params) do
      []
    end

    def set_prs_on_tab(tab, page) do
      Map.put(tab, :pull_requests, page)
    end

    def set_prs_on_tab(tabs, tab, page) do
      updated = set_prs_on_tab(tab, page)

      replace_tabs(tabs, updated)
    end

    # once a tab's data has been updated, we need to poke it back into its
    # place among the list of all tabs
    def replace_tabs(all, updated) when is_list(updated) do
      Enum.reduce(updated, all, fn t, a -> replace_tabs(a, t) end)
    end

    def replace_tabs(all, updated) do
      Mrgr.List.replace(all, updated)
    end

    def remove_pr_from_page(page, pr) do
      case contains_pr?(page, pr) do
        true ->
          entries = Mrgr.List.remove(page.entries, pr)
          updated_count = page.total_entries - 1

          %{page | total_entries: updated_count, entries: entries}

        false ->
          page
      end
    end

    def replace_pr_in_page(page, pr) do
      %{page | entries: Mrgr.List.replace(page.entries, pr)}
    end

    def contains_pr?(%{pull_requests: page} = _tab, pr), do: contains_pr?(page, pr)

    def contains_pr?(%{entries: entries} = _page, pr) do
      Mrgr.List.member?(entries, pr)
    end
  end
end
