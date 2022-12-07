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

      labels = Mrgr.Label.list_for_user(current_user)

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
      |> assign(:labels, labels)
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

  def handle_event("select-tab", %{"id" => id}, socket) do
    selected = Tabs.select_tab(id, socket)

    socket
    |> assign(:selected_tab, selected)
    |> noreply()
  end

  def handle_event("toggle-label", %{"id" => id}, socket) do
    label = Mrgr.List.find(socket.assigns.labels, id)

    tabs =
      case Tabs.present?(socket.assigns.tabs, label) do
        true ->
          Tabs.remove_tab(socket.assigns.tabs, label)

        false ->
          Tabs.add_tab(socket.assigns.tabs, label, socket.assigns.current_user)
      end

    socket
    |> assign(:tabs, tabs)
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
      Tabs.update_pr_data(socket.assigns.tabs, socket.assigns.selected_tab, hydrated)

    selected_pull_request =
      maybe_update_selected_pr(hydrated, socket.assigns.selected_pull_request)

    socket
    |> Flash.put(:info, "Pull Request \"#{pull_request.title}\" updated.")
    |> assign(:tabs, tabs)
    |> assign(:selected_tab, selected_tab)
    |> assign(:selected_pull_request, selected_pull_request)
    |> noreply()
  end

  # async data loading
  def handle_info({ref, result}, socket) do
    # The task succeed so we can cancel the monitoring and discard the DOWN message
    Process.demonitor(ref, [:flush])

    tabs = Tabs.poke_snoozed_data(socket.assigns.tabs, ref, result)

    socket
    |> assign(:tabs, tabs)
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
    import Ecto.Query

    def new(user) do
      [
        %{
          id: "this-week",
          title: "This Week",
          type: :time,
          meta: %{user: user},
          viewing_snoozed: false,
          unsnoozed: :not_loaded,
          snoozed: :not_loaded
        },
        %{
          id: "last-week",
          title: "Last Week",
          type: :time,
          meta: %{user: user},
          viewing_snoozed: false,
          unsnoozed: :not_loaded,
          snoozed: :not_loaded
        },
        %{
          id: "this-month",
          title: "This Month",
          type: :time,
          meta: %{user: user},
          viewing_snoozed: false,
          unsnoozed: :not_loaded,
          snoozed: :not_loaded
        },
        %{
          id: "stale",
          title: "Stale (> 4 weeks)",
          type: :time,
          meta: %{user: user},
          viewing_snoozed: false,
          unsnoozed: :not_loaded,
          snoozed: :not_loaded
        }
      ]
      |> Kernel.++(label_tabs_for_user(user))
      |> Enum.map(&load_snoozed_and_non/1)
    end

    def label_tabs_for_user(user) do
      labels = Mrgr.Label.tabs_for_user(user)

      Enum.map(labels, fn label ->
        build_label_tab(label)
      end)
    end

    defp build_label_tab(label) do
      %{
        id: label.name,
        title: label.name,
        type: :label,
        meta: %{label: label},
        viewing_snoozed: false,
        unsnoozed: :not_loaded,
        snoozed: :not_loaded
      }
    end

    def add_tab(tabs, label, user) do
      query =
        from(q in Mrgr.Schema.LabelPRTab,
          where: q.user_id == ^user.id,
          order_by: [desc: :position],
          limit: 1,
          select: [:position]
        )

      last =
        case Mrgr.Repo.one(query) do
          nil ->
            0

          %{position: position} ->
            position
        end

      {:ok, label_tab} =
        %Mrgr.Schema.LabelPRTab{}
        |> Mrgr.Schema.LabelPRTab.changeset(%{
          position: last + 1,
          user_id: user.id,
          label_id: label.id
        })
        |> Mrgr.Repo.insert()

      label = %{label | pr_tab: label_tab}

      new_tab =
        label
        |> build_label_tab()
        |> load_snoozed_and_non()

      tabs ++ [new_tab]
    end

    def present?(tabs, label) do
      case find_tab(tabs, label) do
        nil -> false
        _ -> true
      end
    end

    def remove_tab(tabs, label) do
      tab = find_tab(tabs, label)
      Mrgr.Repo.delete(tab.meta.label.pr_tab)

      Enum.reject(tabs, fn tab -> tab.id == label.name end)
    end

    def find_tab(tabs, label) do
      Enum.find(tabs, fn tab -> tab.id == label.name end)
    end

    def find_tab_by_ref(tabs, ref) do
      Enum.find(tabs, fn tab -> tab.meta[:ref] == ref end)
    end

    def time_tabs(tabs) do
      Enum.filter(tabs, fn t -> t.type == :time end)
    end

    def label_tabs(tabs) do
      Enum.filter(tabs, fn t -> t.type == :label end)
    end

    def poke_snoozed_data(tabs, ref, data) do
      IO.inspect(ref, label: "ref")

      case find_tab_by_ref(tabs, ref) do
        nil ->
          tabs

        tab ->
          meta = Map.drop(tab.meta, [:ref])

          updated =
            tab
            |> Map.merge(data)
            |> Map.put(:meta, meta)

          Mrgr.List.replace(tabs, updated)
      end
    end

    def update_pr_data(tabs, selected, pr) do
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
      snoozed =
        load_pull_requests(selected, %{snoozed: true, page_number: selected.snoozed.page_number})

      unsnoozed =
        load_pull_requests(selected, %{
          snoozed: false,
          page_number: selected.unsnoozed.page_number
        })

      updated = %{selected | snoozed: snoozed, unsnoozed: unsnoozed}

      {Mrgr.List.replace(all, updated), updated}
    end

    def paginate(params, %{assigns: %{tabs: tabs, selected_tab: selected_tab}}) do
      params = Map.merge(params, %{snoozed: selected_tab.viewing_snoozed})

      page = load_pull_requests(selected_tab, params)

      tabs = set_page(tabs, selected_tab, page)

      selected = select_tab(tabs, selected_tab.id)

      {tabs, selected}
    end

    def select_tab(id, %{assigns: %{tabs: tabs}}) do
      select_tab(tabs, id)
    end

    def select_tab(tabs, id) do
      Enum.find(tabs, fn i -> i.id == id end)
    end

    def select_pull_request(tab, id) do
      tab
      |> viewing_page()
      |> Map.get(:entries)
      |> select_tab(id)
    end

    def viewing_page(tab) do
      case tab.viewing_snoozed do
        true -> tab.snoozed
        false -> tab.unsnoozed
      end
    end

    def load_snoozed_and_non(tab, opts \\ %{}) do
      task =
        Task.async(fn ->
          %{
            snoozed: load_pull_requests(tab, Map.put(opts, :snoozed, true)),
            unsnoozed: load_pull_requests(tab, Map.put(opts, :snoozed, false))
          }
        end)

      meta = tab.meta

      %{tab | meta: Map.put(meta, :ref, task.ref)}
    end

    def load_pull_requests(tab, page_params \\ %{})

    def load_pull_requests(%{id: "this-week"} = tab, page_params) do
      opts = Map.merge(page_params, %{since: this_week()})

      Mrgr.PullRequest.paged_pending_pull_requests(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "last-week"} = tab, page_params) do
      opts = Map.merge(page_params, %{before: this_week(), since: two_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "this-month"} = tab, page_params) do
      opts = Map.merge(page_params, %{before: two_weeks_ago(), since: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(tab.meta.user, opts)
    end

    def load_pull_requests(%{id: "stale"} = tab, page_params) do
      opts = Map.merge(page_params, %{before: four_weeks_ago()})
      Mrgr.PullRequest.paged_pending_pull_requests(tab.meta.user, opts)
    end

    def load_pull_requests(tab, page_params) do
      Mrgr.PullRequest.paged_for_label(tab.meta.label, page_params)
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
