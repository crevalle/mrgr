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

      # id will be `nil` for the index action
      # but present for the show action
      # detail = Mrgr.List.find(pull_requests, params["id"])
      # not sure how to do this anymore

      socket
      |> assign(:tabs, tabs)
      |> assign(:selected_tab, hd(tabs))
      |> assign(:detail, nil)
      |> assign(:selected_attr, nil)
      |> assign(:repos, repos)
      |> assign(:labels, labels)
      |> assign(:members, members)
      |> assign(:snooze_options, snooze_options)
      |> assign(:frozen_repos, frozen_repos)
      |> put_title("Open Pull Requests")
      |> ok()
    else
      ok(socket)
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

  def handle_event("edit-tab", _params, socket) do
    socket
    |> assign(:detail, socket.assigns.selected_tab)
    |> show_detail()
    |> noreply()
  end

  def handle_event("update-tab", %{"tab" => params}, socket) do
    {tabs, updated_tab} = Tabs.update(socket.assigns.tabs, socket.assigns.selected_tab, params)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, updated_tab)
    |> assign(:detail, nil)
    |> hide_detail()
    |> noreply()
  end

  def handle_event("select-tab", %{"id" => id}, socket) do
    selected = Tabs.select(socket.assigns.tabs, id)

    socket
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

  def handle_event("toggle-viewing-snoozed", _params, socket) do
    {tabs, selected_tab} = Tabs.toggle_snoozed(socket)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> noreply()
  end

  def handle_event("snooze", %{"snooze_id" => snooze_id, "pr_id" => pull_request_id}, socket) do
    pull_request = Tabs.find_pull_request(socket.assigns.selected_tab, pull_request_id)

    Mrgr.PullRequest.snooze(pull_request, translate_snooze(snooze_id))

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, socket.assigns.selected_tab)

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

  def handle_event("unsnooze-pull-request", %{"id" => id}, socket) do
    pull_request = Tabs.find_pull_request(socket.assigns.selected_tab, id)

    pull_request = Mrgr.PullRequest.unsnooze(pull_request)

    {tabs, selected} = Tabs.reload_prs(socket.assigns.tabs, socket.assigns.selected_tab)

    # update in place to reflect new status
    socket =
      case previewing_pull_request?(socket.assigns.detail, pull_request) do
        true ->
          assign(socket, :detail, pull_request)

        false ->
          socket
      end

    socket
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
             @pull_request_labels_updated,
             @pull_request_ci_status_updated
           ] do
    hydrated = Mrgr.PullRequest.preload_for_pending_list(pull_request)

    {tabs, selected_tab} =
      Tabs.update_pr_data(socket.assigns.tabs, socket.assigns.selected_tab, hydrated)

    selected_pull_request = maybe_update_selected_pr(hydrated, socket.assigns.detail)

    socket
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> assign(:detail, selected_pull_request)
    |> noreply()
  end

  # async data loading
  def handle_info({ref, result}, socket) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])

    tabs = Tabs.poke_snoozed_data(socket.assigns.tabs, ref, result)
    selected_tab = Tabs.poke_snoozed_data(socket.assigns.selected_tab, ref, result)

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

  def selected?(%{id: id}, %{id: id}), do: true
  def selected?(_pull_request, _selected), do: false

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

  def pull_requests(selected) do
    Tabs.get_page(selected)
  end

  def custom?(tab) do
    Tabs.custom?(tab)
  end

  defmodule Tabs do
    def new(user) do
      []
      |> Kernel.++(state_tabs_for_user(user))
      |> Kernel.++(custom_tabs_for_user(user))
      |> Enum.map(&load_prs_async/1)
    end

    def add(tabs, user) do
      new_tab = Mrgr.PRTab.create(user)
      updated_tabs = tabs ++ [new_tab]

      {updated_tabs, new_tab}
    end

    def update(tabs, tab, params) do
      {:ok, updated_tab} = Mrgr.PRTab.update(tab, params)

      updated_tabs = reload_tab(tabs, updated_tab)

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

    def state_tabs_for_user(user) do
      [
        %{
          id: "ready-to-merge",
          title: "🚀 Ready to Merge",
          type: :state,
          meta: %{user: user},
          viewing_snoozed: false,
          pull_requests: [],
          snoozed: []
        },
        %{
          id: "needs-approval",
          title: "⚠️ Needs Approval",
          type: :state,
          meta: %{user: user},
          viewing_snoozed: false,
          pull_requests: [],
          snoozed: []
        },
        %{
          id: "fix-ci",
          title: "🛠 Fix CI",
          type: :state,
          meta: %{user: user},
          viewing_snoozed: false,
          pull_requests: [],
          snoozed: []
        },
        %{
          id: "hifs",
          title: "💥 High Impact Changes",
          type: :state,
          meta: %{user: user},
          viewing_snoozed: false,
          pull_requests: [],
          snoozed: []
        },
        %{
          id: "snoozed",
          title: "😴 Snoozed",
          type: :state,
          meta: %{user: user},
          viewing_snoozed: false,
          pull_requests: [],
          snoozed: []
        }
      ]
    end

    def custom_tabs_for_user(user) do
      Mrgr.PRTab.for_user(user)
    end

    def find_tab_by_ref(tabs, ref) do
      Enum.find(tabs, fn tab -> tab.meta[:ref] == ref end)
    end

    def state_tabs(tabs) do
      Enum.reject(tabs, &custom?/1)
    end

    def custom_tabs(tabs) do
      Enum.filter(tabs, &custom?/1)
    end

    def custom?(%Mrgr.Schema.PRTab{}), do: true
    def custom?(_), do: false

    def poke_snoozed_data(tabs, ref, data) when is_list(tabs) do
      case find_tab_by_ref(tabs, ref) do
        nil ->
          tabs

        tab ->
          updated = poke_snoozed_data(tab, ref, data)

          Mrgr.List.replace(tabs, updated)
      end
    end

    # data for the currently visible tab
    def poke_snoozed_data(%{meta: %{ref: ref}} = tab, ref, data) do
      meta = Map.drop(tab.meta, [:ref])

      tab
      |> Map.merge(data)
      |> Map.put(:meta, meta)
    end

    # data for a different tab
    def poke_snoozed_data(tab, _ref, _data), do: tab

    def update_pr_data(tabs, selected, pr) do
      # slow, dumb traversal through everything.  ignore snoozed stuff
      tabs =
        Enum.map(tabs, fn tab ->
          pull_requests = Mrgr.List.replace(tab.pull_requests, pr)
          %{tab | pull_requests: pull_requests}
        end)

      selected = %{selected | pull_requests: Mrgr.List.replace(selected.pull_requests, pr)}

      {tabs, selected}
    end

    def reload_prs(all, selected) do
      snoozed =
        load_pull_requests(selected, %{
          snoozed: true,
          page_number: safe_page_number(selected.snoozed)
        })

      pull_requests =
        load_pull_requests(selected, %{
          snoozed: false,
          page_number: safe_page_number(selected.pull_requests)
        })

      updated = %{selected | snoozed: snoozed, pull_requests: pull_requests}

      {Mrgr.List.replace(all, updated), updated}
    end

    # newly created tabs don't have a hydrated snoozed field
    def safe_page_number(nil), do: 1
    def safe_page_number([]), do: 1

    def safe_page_number(snoozed_or_unsnoozed) do
      snoozed_or_unsnoozed.page_number
    end

    def paginate(params, %{assigns: %{tabs: tabs, selected_tab: selected_tab}}) do
      params = Map.merge(params, %{snoozed: selected_tab.viewing_snoozed})

      page = load_pull_requests(selected_tab, params)

      tabs = set_page(tabs, selected_tab, page)

      selected = Mrgr.List.find(tabs, selected_tab.id)

      {tabs, selected}
    end

    def select(tabs, id) do
      # Mrgr.List.find currently coerces ids to integers
      # because of legacy handling in live view params
      # here we want to tolerate both integers and strings (tabs have
      # string ids) so just do the search manually
      Enum.find(tabs, fn t -> t.id == id end)
    end

    def find_pull_request(tab, id) do
      tab
      |> viewing_page()
      |> Map.get(:entries)
      |> Mrgr.List.find(id)
    end

    def viewing_page(tab) do
      case tab.viewing_snoozed do
        true -> tab.snoozed
        false -> tab.pull_requests
      end
    end

    def load_prs_async(tab, opts \\ %{}) do
      task =
        Task.async(fn ->
          %{
            pull_requests: load_pull_requests(tab)
          }
        end)

      meta = tab.meta

      %{tab | meta: Map.put(meta, :ref, task.ref)}
    end

    def load_pull_requests(tab, page_params \\ %{})

    def load_pull_requests(%{id: "ready-to-merge"} = tab, opts) do
      Mrgr.PullRequest.paged_ready_to_merge_prs(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "needs-approval"} = tab, opts) do
      Mrgr.PullRequest.paged_needs_approval_prs(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "fix-ci"} = tab, opts) do
      Mrgr.PullRequest.paged_fix_ci_prs(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "hifs"} = tab, opts) do
      Mrgr.PullRequest.paged_high_impact_prs(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "snoozed"} = tab, opts) do
      Mrgr.PullRequest.paged_snoozed_prs(tab.meta.user, opts)
    end

    def load_pull_requests(%Mrgr.Schema.PRTab{} = tab, opts) do
      Mrgr.PullRequest.paged_nav_tab_prs(tab, opts)
    end

    def load_pull_requests(_unknown_tab, _params) do
      []
    end

    def set_page(all, selected, page) do
      updated =
        case selected.viewing_snoozed do
          true -> Map.put(selected, :snoozed, page)
          false -> Map.put(selected, :pull_requests, page)
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
    def get_page(%{viewing_snoozed: false, pull_requests: prs}), do: prs
  end
end
