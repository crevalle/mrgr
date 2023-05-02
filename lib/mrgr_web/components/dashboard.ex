defmodule MrgrWeb.Components.Dashboard do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.PullRequest

  alias MrgrWeb.PullRequestDashboardLive.Tabs

  def nav_tab_menu(assigns) do
    ~H"""
    <.nav_tab_list>
      <.tab_section>
        <:title>
          Next Action
        </:title>

        <.nav_tab
          :for={tab <- Tabs.action_state_tabs(@tabs)}
          tab={tab}
          selected?={selected?(tab, @selected_tab)}
        />
      </.tab_section>

      <.tab_section>
        <:title>
          Needs Attention
        </:title>

        <.nav_tab
          :for={tab <- Tabs.needs_attention_tabs(@tabs)}
          tab={tab}
          selected?={selected?(tab, @selected_tab)}
        />
      </.tab_section>

      <.tab_section>
        <:title>
          Summary
        </:title>

        <.nav_tab
          :for={tab <- Tabs.summary_tabs(@tabs)}
          tab={tab}
          selected?={selected?(tab, @selected_tab)}
        />
      </.tab_section>

      <.tab_section>
        <:title>
          Custom
        </:title>

        <.nav_tab
          :for={tab <- Tabs.custom_tabs(@tabs)}
          tab={tab}
          selected?={selected?(tab, @selected_tab)}
        />
        <.l phx-click="add-tab">
          <.icon name="plus-circle" type="solid" class="ml-2 h-5 w-5" />
        </.l>
      </.tab_section>
    </.nav_tab_list>
    """
  end

  def nav_tab_list(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4 w-64">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :editing, :boolean, default: false
  attr :selected?, :boolean, default: false
  attr :tab, :map

  def nav_tab(%{tab: %{editing: true}} = assigns) do
    ~H"""
    <div
      class="tab-select-button selected"
      id={"#{@tab.id}-tab"}
      aria-selected="false"
      role="presentation"
    >
      <div class="flex items-center justify-between">
        <div class="flex flex-col space-y-1">
          <.form :let={f} for={%{}} as={:tab} phx-submit="save-tab" phx-click-away="cancel-tab-edit">
            <%= text_input(f, :title,
              value: "#{@tab.title}",
              placeholder: "name this tab",
              autofocus: true,
              class:
                "text-gray-700 py-1 px-1.5 outline-none focus:outline-none focus:ring-teal-500 focus:border-teal-500 w-40 text-sm rounded-md"
            ) %>
          </.form>
          <p class="text-xs text-gray-500">Press Enter to Save</p>
        </div>

        <.pr_count_badge items={@tab.pull_requests} />
      </div>
    </div>
    """
  end

  def nav_tab(%{tab: %Mrgr.Schema.PRTab{}, selected?: true} = assigns) do
    ~H"""
    <div
      class="tab-select-button selected"
      id={"#{@tab.id}-tab"}
      aria-selected="true"
      role="presentation"
    >
      <.tab_name class="cursor-text" phx-click={JS.push("edit-tab", value: %{id: @tab.id})}>
        <:title><%= @tab.title %></:title>
        <:count>
          <.pr_count_badge items={@tab.pull_requests} />
        </:count>
      </.tab_name>
    </div>
    """
  end

  def nav_tab(%{selected?: true} = assigns) do
    ~H"""
    <div
      class="tab-select-button selected"
      id={"#{@tab.id}-tab"}
      aria-selected="true"
      role="presentation"
    >
      <.tab_name>
        <:title>
          <%= @tab.title %>
        </:title>
        <:count>
          <.pr_count_badge items={@tab.pull_requests} />
        </:count>
      </.tab_name>
    </div>
    """
  end

  def nav_tab(assigns) do
    ~H"""
    <.link
      patch={~p"/pull-requests/#{@tab.permalink}"}
      class="tab-select-button"
      id={"#{@tab.id}-tab"}
      aria-selected="false"
      role="presentation"
    >
      <.tab_name>
        <:title>
          <%= @tab.title %>
        </:title>
        <:count>
          <.pr_count_badge items={@tab.pull_requests} />
        </:count>
      </.tab_name>
    </.link>
    """
  end

  attr :rest, :global

  slot :title, default: "untitled"
  slot :count

  def tab_name(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <p {@rest}><%= render_slot(@title) %></p>
      <%= render_slot(@count) %>
    </div>
    """
  end

  def tab_heading(assigns) do
    ~H"""
    <div class="white-box">
      <.h2><%= @tab.title %></.h2>
      <.tab_subtitle tab={@tab} />

      <MrgrWeb.Components.PullRequestFilter.filters
        :if={custom_tab?(@tab)}
        tab={@tab}
        labels={@labels}
        members={@members}
        repos={@repos}
        draft_statuses={@draft_statuses}
      />
    </div>
    """
  end

  def tab_explanation(assigns) do
    ~H"""
    <span class="text-sm text-gray-400">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  def tab_subtitle(%{tab: %{id: "ready-to-merge"}} = assigns) do
    ~H"""
    <.tab_explanation>
      Ready to Merge pull requests have been approved (or need no approvals) and are passing CI.  Merge them!
    </.tab_explanation>
    """
  end

  def tab_subtitle(%{tab: %{id: "needs-approval"}} = assigns) do
    ~H"""
    <.tab_explanation>
      Needs Approval pull requests are passing CI but require more approvals from your team in order to merge.  Ping your team or assign more reviewers to move them along.
    </.tab_explanation>
    """
  end

  def tab_subtitle(%{tab: %{id: "fix-ci"}} = assigns) do
    ~H"""
    <.tab_explanation>
      These PRs are failing CI.  They may or may not also be fully approved, but any CI issues need to be resolved before they can be merged and should be resolved before any further approvals.
    </.tab_explanation>
    """
  end

  def tab_subtitle(%{tab: %{id: "hifs"}} = assigns) do
    ~H"""
    <.tab_explanation>
      These PRs contain changes to files designated High Impact.  Take an extra look before you merge them!
    </.tab_explanation>
    """
  end

  def tab_subtitle(%{tab: %{id: "dormant"}} = assigns) do
    ~H"""
    <.tab_explanation>
      Dormant PRs have recently gone quiet.  It's been at least 24 hours - but less than 72 - since the last commit, comment, or review (weekends are NOT included in this calculation).  To prevent them from going stale, they should be revived immediately by pinging your team.
    </.tab_explanation>
    """
  end

  def tab_subtitle(%{tab: %{id: "snoozed"}} = assigns) do
    ~H"""
    <.tab_explanation>
      Snoozed PRs are hidden from your main workflow and aren't included in the badge counts.  They may be things you want to deal with later, like in a day or two, or things that are outstanding and just noise.
    </.tab_explanation>
    """
  end

  def tab_subtitle(assigns), do: ~H[]

  slot :title
  slot :header_detail
  slot :inner_block, required: true

  def tab_section(assigns) do
    ~H"""
    <div class="flex flex-col space-y">
      <p class="font-semibold text-sm text-gray-400 uppercase">
        <%= render_slot(@title) %>
      </p>

      <div class="flex flex-col space-y">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def render_detail(assigns) do
    ~H"""
    <div class="rounded-md">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between items-center">
          <.h3>
            <.detail_title pull_request={@pull_request} attr={@attr} />
          </.h3>
          <.link patch={@close}>
            <.icon name="x-circle" class="text-teal-700 hover:text-teal-500 mr-1 h-5 w-5" />
          </.link>
        </div>
        <.detail_content pull_request={@pull_request} attr={@attr} timezone={@timezone} />
      </div>
    </div>
    """
  end

  def detail_title(%{attr: "comments"} = assigns) do
    ~H"""
    <%= @pull_request.title %> - Comments (<%= Enum.count(@pull_request.comments) %>)
    """
  end

  def detail_title(%{attr: "commits"} = assigns) do
    ~H"""
    <%= @pull_request.title %> - Commits (<%= Enum.count(@pull_request.commits) %>)
    """
  end

  def detail_title(%{attr: "files-changed"} = assigns) do
    ~H"""
    <%= @pull_request.title %> - Files Changed (<%= Enum.count(@pull_request.files_changed) %>)
    """
  end

  def detail_content(%{attr: "comments"} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-4 divide-y divide-gray-200">
      <.render_comment
        :for={comment <- Mrgr.Schema.Comment.cron(@pull_request.comments)}
        comment={comment}
        tz={@timezone}
      />
    </div>
    """
  end

  def detail_content(%{attr: "commits"} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-4 divide-y divide-gray-200">
      <.render_commit :for={commit <- @pull_request.commits} commit={commit} tz={@timezone} />
    </div>
    """
  end

  def detail_content(%{attr: "files-changed"} = assigns) do
    ~H"""
    <.hif_badge_list hifs={@pull_request.high_impact_file_rules} />

    <.changed_file_list
      files_changed={@pull_request.files_changed}
      hifs={@pull_request.high_impact_file_rules}
    />
    """
  end

  def selected?(%{id: id}, %{id: id}), do: true
  def selected?(_pull_request, _selected), do: false

  def custom_tab?(tab), do: MrgrWeb.PullRequestDashboardLive.custom?(tab)
end
