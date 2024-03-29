defmodule MrgrWeb.PullRequestDashboardLive do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.Dashboard
  import MrgrWeb.Components.PullRequest, only: [card: 1]

  alias __MODULE__.Tabs

  on_mount MrgrWeb.Plug.Auth

  def mount(params, _session, socket) do
    if connected?(socket) do
      socket
      |> assign_timezone()
      |> assign_all_the_things(params)
      |> put_title("Open Pull Requests")
      |> ok()
    else
      socket
      |> ok()
    end
  end

  def assign_all_the_things(
        %{assigns: %{current_user: %{nickname: "desmondmonster"}}} = socket,
        %{"as_user_id" => user_id}
      ) do
    user = Mrgr.User.find(user_id)
    data = load_data_for_user(user)

    socket
    |> assign(data)
    |> Flash.put(:info, "Showing data for #{user.nickname}")
  end

  def assign_all_the_things(socket, _params) do
    current_user = socket.assigns.current_user

    subscribe(current_user)
    set_dormancy_timer()

    assign(socket, load_data_for_user(current_user))
  end

  def load_data_for_user(user) do
    repos = Mrgr.Repository.for_user_with_hif_rules(user)
    frozen_repos = filter_frozen_repos(repos)

    visible_repo_count =
      Mrgr.Repo.aggregate(Mrgr.User.visible_repos_at_current_installation(user), :count)

    labels = Mrgr.Label.list_for_user(user)
    members = Mrgr.Repo.all(Mrgr.Member.for_installation(user.current_installation_id))

    tabs = Tabs.new(user)

    %{
      detail: nil,
      selected_attr: nil,
      tabs: tabs,
      repos: repos,
      labels: labels,
      members: members,
      draft_statuses: Mrgr.PRTab.draft_statuses(),
      snooze_options: snooze_options(),
      frozen_repos: frozen_repos,
      visible_repo_count: visible_repo_count
    }
  end

  def assign_timezone(socket) do
    MrgrWeb.Plug.Auth.assign_user_timezone(socket)
  end

  # go to a specific PR on a tab
  def handle_params(%{"attr" => attr, "pull_request_id" => pr_id, "tab" => id}, _uri, socket) do
    if connected?(socket) do
      selected = get_tab(socket.assigns.tabs, id)
      pr = Tabs.find_pull_request(selected, pr_id)

      socket
      |> assign(:selected_tab, selected)
      |> assign(:detail, pr)
      |> assign(:selected_attr, attr)
      |> show_detail()
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  # go to a tab
  def handle_params(%{"tab" => id}, _uri, socket) do
    if connected?(socket) do
      selected = get_tab(socket.assigns.tabs, id)

      socket
      |> assign(:selected_tab, selected)
      |> assign(:detail, nil)
      |> assign(:selected_attr, nil)
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  # index action
  def handle_params(_params, _uri, socket) do
    if connected?(socket) do
      default_tab = select_default_tab(socket.assigns.tabs)

      socket
      |> assign(:selected_tab, default_tab)
      |> noreply()
    else
      socket
      |> noreply()
    end
  end

  def select_default_tab(tabs) do
    tabs
    |> Tabs.custom_tabs()
    |> case do
      [] ->
        hd(tabs)

      [first | _rest] ->
        first
    end
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
    |> push_patch(to: ~p"/pull-requests/#{updated_tab.permalink}")
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

  def handle_event("toggle-reviewer", %{"id" => id}, socket) do
    reviewer = Mrgr.List.find(socket.assigns.members, id)
    selected_tab = socket.assigns.selected_tab

    updated_tab = Mrgr.PRTab.toggle_reviewer(selected_tab, reviewer)

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

  def handle_event("toggle-draft-status", %{"id" => id}, socket) do
    selected_tab = socket.assigns.selected_tab
    status = Mrgr.List.find(socket.assigns.draft_statuses, id)

    updated_tab = Mrgr.PRTab.update_draft_status(selected_tab, status.value)

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, updated_tab)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("snooze", %{"snooze_id" => snooze_id, "pr_id" => pull_request_id}, socket) do
    pull_request =
      socket.assigns.selected_tab
      |> Tabs.find_pull_request(pull_request_id)
      |> Mrgr.PullRequest.snooze_for_user(
        socket.assigns.current_user,
        translate_snooze(snooze_id)
      )

    tabs = Tabs.snooze(socket.assigns.tabs, pull_request)
    selected = get_selected_tab(tabs, socket)

    socket
    |> hide_detail_if_previewing(pull_request)
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected)
    |> Flash.put(:info, "PR snoozed 😴")
    |> noreply()
  end

  def handle_event("unsnooze", %{"pr_id" => id}, socket) do
    # updating state in the socket happens when the event bus is called
    # because the system may unsnooze PRs
    socket.assigns.selected_tab
    |> Tabs.find_pull_request(id)
    |> Mrgr.PullRequest.unsnooze_for_user(socket.assigns.current_user)

    socket
    |> noreply()
  end

  def set_dormancy_timer do
    # ms
    one_hour = 60 * 60 * 1000

    Process.send_after(self(), :refresh_dormancy, one_hour)
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

  def handle_info(:refresh_dormancy, socket) do
    set_dormancy_timer()

    # the async handler takes care of the currently selected tab
    tabs = Tabs.refresh_dormant_tab(socket.assigns.tabs)

    socket
    |> assign(:tabs, tabs)
    |> noreply()
  end

  def handle_info(%{event: event, payload: payload}, socket)
      when event in [
             @pull_request_created,
             @pull_request_reopened,
             @pull_request_ready_for_review
           ] do
    hydrated = Mrgr.PullRequest.preload_for_dashboard(payload, socket.assigns.current_user)
    tabs = Tabs.receive_opened_pull_request(socket.assigns.tabs, hydrated)
    selected_tab = get_selected_tab(tabs, socket)

    socket
    |> Flash.put(:info, "PR opened: #{hydrated.title}")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_info(%{event: @pull_request_closed, payload: payload}, socket) do
    tabs = Tabs.excise_pr_from_all_tabs(socket.assigns.tabs, payload)
    selected_tab = get_selected_tab(tabs, socket)

    socket
    |> put_closed_flash_message(payload)
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_info(%{event: @pull_request_unsnoozed, payload: pull_request}, socket) do
    hydrated = Mrgr.PullRequest.preload_for_dashboard(pull_request, socket.assigns.current_user)

    tabs = Tabs.unsnooze(socket.assigns.tabs, hydrated)
    selected_tab = get_selected_tab(tabs, socket)

    selected_pull_request = maybe_update_selected_pr(hydrated, socket.assigns.detail)

    socket
    |> Flash.put(:info, "PR unsnoozed! ☀️")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> assign(:detail, selected_pull_request)
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
    hydrated = Mrgr.PullRequest.preload_for_dashboard(pull_request, socket.assigns.current_user)

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

  def handle_info(%{event: @pull_request_converted_to_draft, payload: pull_request}, socket) do
    tabs = Tabs.convert_pr_to_draft(socket.assigns.tabs, pull_request)
    selected_tab = get_selected_tab(tabs, socket)

    socket
    |> Flash.put(:info, "PR converted to draft: #{pull_request.title}")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
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

  def hide_detail_if_previewing(socket, pull_request) do
    case previewing_pull_request?(socket.assigns.detail, pull_request) do
      true ->
        hide_detail(socket)

      false ->
        socket
    end
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
    get_tab(tabs, socket.assigns.selected_tab.permalink)
  end

  def get_tab(tabs, permalink) do
    Tabs.find_tab_by_permalink(tabs, permalink)
  end

  defmodule Tabs do
    @ready_to_merge "ready-to-merge"
    @needs_approval "needs-approval"
    @fix_ci "fix-ci"
    @snoozed "snoozed"
    @all "all"
    @hifs "hifs"
    @dormant "dormant"

    def new(user) do
      []
      |> Kernel.++(system_tabs_for_user(user))
      |> Kernel.++(custom_tabs_for_user(user))
      |> Enum.map(&load_prs_sync/1)
    end

    def add(tabs, user) do
      new_tab = Mrgr.PRTab.create_for_user(user)
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
          permalink: @ready_to_merge,
          title: "🚀 Ready to Merge",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @needs_approval,
          permalink: @needs_approval,
          title: "⚠️ Needs Approval",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @fix_ci,
          permalink: @fix_ci,
          title: "🛠 Fix CI",
          type: "action_state",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @hifs,
          permalink: @hifs,
          title: "💥 High Impact",
          type: "needs_attention",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @dormant,
          permalink: @dormant,
          title: "🥀 Dormant",
          type: "needs_attention",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @all,
          permalink: @all,
          title: "🌎 All",
          type: "summary",
          meta: %{user: user},
          pull_requests: []
        },
        %{
          id: @snoozed,
          permalink: @snoozed,
          title: "😴 Snoozed",
          type: "summary",
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

    def find_tab_by_permalink(tabs, permalink) do
      Enum.find(tabs, fn i -> i.permalink == permalink end)
    end

    def action_state_tabs(tabs) do
      Enum.filter(tabs, &action_state?/1)
    end

    def needs_attention_tabs(tabs) do
      Enum.filter(tabs, &needs_attention?/1)
    end

    def summary_tabs(tabs) do
      Enum.filter(tabs, &summary?/1)
    end

    def system_tabs(tabs) do
      Enum.reject(tabs, &custom?/1)
    end

    def custom_tabs(tabs) do
      Enum.filter(tabs, &custom?/1)
    end

    def summary?(%{type: "summary"}), do: true
    def summary?(_), do: false

    def action_state?(%{type: "action_state"}), do: true
    def action_state?(_), do: false

    def needs_attention?(%{type: "needs_attention"}), do: true
    def needs_attention?(_), do: false

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
    def set_prs_on_tab_from_async(%{meta: %{ref: ref}} = tab, ref, prs) do
      meta = Map.drop(tab.meta, [:ref])

      tab
      |> set_prs_on_tab(prs)
      |> Map.put(:meta, meta)
    end

    # data for a different tab
    def set_prs_on_tab_from_async(tab, _ref, _data), do: tab

    def update_pull_request(tabs, pr) do
      tabs
      |> excise_pr_from_tab(@dormant, pr)
      |> update_action_state_tabs(pr)
      # replaces the PR again in the action state tabs, but i don't
      # care about the extra work rn.  this code is simpler than extracting
      # non action state tabs and just replacing it in those.  can optimize laterz
      |> Enum.map(&replace_pr_in_tab(&1, pr))
    end

    def excise_pr_from_all_tabs(tabs, pr) when is_list(tabs) do
      Enum.map(tabs, &excise_pr_from_tab(&1, pr))
    end

    def update_action_state_tabs(tabs, %{draft: true}), do: tabs

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

    # TODO: pull from snoozed tab
    # poke into HIF tab
    def receive_opened_pull_request(tabs, pr) do
      tabs
      |> start_pr_in_needs_approval(pr)
      |> refresh_custom_tabs()
    end

    def convert_pr_to_draft(tabs, pull_request) do
      tabs
      |> excise_pr_from_system_tabs(pull_request)
      |> refresh_custom_tabs()
    end

    def excise_pr_from_system_tabs(tabs, pull_request) do
      tabs
      |> system_tabs()
      |> Enum.reduce(tabs, fn tab, acc ->
        excise_pr_from_tab(acc, tab.id, pull_request)
      end)
    end

    def refresh_custom_tabs(tabs) do
      refreshing =
        tabs
        |> custom_tabs()
        |> Enum.map(&refresh_tab_async/1)

      replace_tabs(tabs, refreshing)
    end

    # drafts don't go in our regular tabs
    defp start_pr_in_needs_approval(tabs, %{draft: true}), do: tabs

    defp start_pr_in_needs_approval(tabs, pr) do
      needs_approval =
        tabs
        |> find_tab_by_id(@needs_approval)
        |> poke_pr_into_tab(pr)

      replace_tab(tabs, needs_approval)
    end

    def snooze(tabs, pull_request) do
      snoozed_tab =
        tabs
        |> find_tab_by_id(@snoozed)
        |> poke_pr_into_tab(pull_request)

      # PR can appear on several different tabs, remove from all
      tabs
      |> excise_pr_from_all_tabs(pull_request)
      |> replace_tabs(snoozed_tab)
    end

    # hard to be smart about poking in the PR to system tabs
    # because the pr may not supposed be on the currently viewed list.
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
      updated_list = remove_pr_from_list(tab.pull_requests, pull_request)

      set_prs_on_tab(tab, updated_list)
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
      prs = [pull_request | tab.pull_requests]

      set_prs_on_tab(tab, prs)
    end

    def replace_pr_in_tab(tab, pull_request) do
      prs = replace_pr_in_list(tab.pull_requests, pull_request)
      set_prs_on_tab(tab, prs)
    end

    def refresh_dormant_tab(tabs) do
      dormant =
        tabs
        |> find_tab_by_id(@dormant)
        |> refresh_tab_async()

      replace_tab(tabs, dormant)
    end

    def refresh_non_snoozed_tabs_async(tabs) do
      refreshing =
        tabs
        |> Enum.reject(&snoozed?/1)
        |> Enum.map(&refresh_tab_async/1)

      replace_tabs(tabs, refreshing)
    end

    def refresh_tab_async(tab) do
      load_prs_async(tab)
    end

    def reload_prs(all, selected) do
      pull_requests = fetch_pull_requests(selected)

      updated = set_prs_on_tab(selected, pull_requests)

      {replace_tabs(all, updated), updated}
    end

    def find_pull_request(tab, id) do
      tab.pull_requests
      |> Mrgr.List.find(id)
    end

    def load_prs_sync(tab) do
      prs = fetch_pull_requests(tab)

      tab
      |> set_prs_on_tab(prs)
    end

    def load_prs_async(tab) do
      task = Task.async(fn -> fetch_pull_requests(tab) end)

      meta = tab.meta

      %{tab | meta: Map.put(meta, :ref, task.ref)}
    end

    def fetch_pull_requests(tab)

    def fetch_pull_requests(%{id: @ready_to_merge} = tab) do
      Mrgr.PullRequest.ready_to_merge_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @needs_approval} = tab) do
      Mrgr.PullRequest.needs_approval_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @fix_ci} = tab) do
      Mrgr.PullRequest.fix_ci_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @hifs} = tab) do
      Mrgr.PullRequest.high_impact_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @dormant} = tab) do
      Mrgr.PullRequest.dormant_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @snoozed} = tab) do
      Mrgr.PullRequest.snoozed_prs(tab.meta.user)
    end

    def fetch_pull_requests(%{id: @all} = tab) do
      Mrgr.PullRequest.open_prs(tab.meta.user)
    end

    def fetch_pull_requests(%Mrgr.Schema.PRTab{} = tab) do
      Mrgr.PullRequest.custom_tab_prs(tab)
    end

    def fetch_pull_requests(_unknown_tab) do
      []
    end

    def set_prs_on_tab(tab, prs) do
      Map.put(tab, :pull_requests, prs)
    end

    def set_prs_on_tab(tabs, tab, prs) do
      updated = set_prs_on_tab(tab, prs)

      replace_tabs(tabs, updated)
    end

    # once a tab's data has been updated, we need to poke it back into its
    # place among the list of all tabs
    def replace_tabs(all, updated) when is_list(updated) do
      Enum.reduce(updated, all, fn t, a -> replace_tab(a, t) end)
    end

    def replace_tabs(all, updated), do: replace_tab(all, updated)

    def replace_tab(all, updated) do
      Mrgr.List.replace(all, updated)
    end

    def remove_pr_from_list(pull_requests, pr) do
      Mrgr.List.remove(pull_requests, pr)
    end

    def replace_pr_in_list(pull_requests, pr) do
      Mrgr.List.replace(pull_requests, pr)
    end

    def contains_pr?(%{pull_requests: prs}, pr) when is_list(prs) do
      case Mrgr.List.find(prs, pr) do
        nil -> false
        _item -> true
      end
    end
  end
end
