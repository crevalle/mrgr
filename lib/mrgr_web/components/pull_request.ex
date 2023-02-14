defmodule MrgrWeb.Components.PullRequest do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  alias Mrgr.Schema.PullRequest
  alias Phoenix.LiveView.JS

  def render_detail(%{item: %Mrgr.Schema.PullRequest{}} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-6 bg-white rounded-md">
      <.pull_request_detail pull_request={@item} attr={@attr} timezone={@timezone} />
    </div>
    """
  end

  def pull_request_detail(%{attr: "comments"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        <%= @pull_request.title %> - Comments (<%= Enum.count(@pull_request.comments) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_comment
          :for={comment <- Mrgr.Schema.Comment.ordered(@pull_request.comments)}
          comment={comment}
          tz={@timezone}
        />
      </div>
    </.detail_content>
    """
  end

  def pull_request_detail(%{attr: "commits"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        <%= @pull_request.title %> - Commits (<%= Enum.count(@pull_request.commits) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_commit :for={commit <- @pull_request.commits} commit={commit} tz={@timezone} />
      </div>
    </.detail_content>
    """
  end

  def pull_request_detail(%{attr: "files-changed"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        <%= @pull_request.title %> - Files Changed (<%= Enum.count(@pull_request.files_changed) %>)
      </:title>

      <.hif_badge_list hifs={@pull_request.high_impact_files} />

      <div class="flex flex-col space-y-0 leading-tight">
        <.changed_file
          :for={f <- @pull_request.files_changed}
          filename={f}
          hifs={@pull_request.high_impact_files}
        />
      </div>
    </.detail_content>
    """
  end

  def hif_badge_list(%{hifs: []} = assigns) do
    ~H[]
  end

  def hif_badge_list(assigns) do
    ~H"""
    <div class="flex">
      <span>💥</span>
      <div class="mt-2 flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
        <.badge :for={hif <- @hifs} item={hif} />
      </div>
    </div>
    """
  end

  def changed_file(assigns) do
    matching_file =
      Enum.find(
        assigns.hifs,
        &Mrgr.HighImpactFile.pattern_matches_filename?(assigns.filename, &1)
      )

    color =
      case matching_file do
        nil -> "transparent"
        file -> file.color
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <div style={"border-color: #{@color};"} class="border-l-4"><pre><%= @filename %></pre></div>
    """
  end

  def reviewers(%{reviewers: []} = assigns) do
    ~H"""
    <span class="text-gray-500 italic text-sm">no reviewers requested</span>
    """
  end

  def reviewers(assigns) do
    assigns =
      assigns
      |> assign(:count, Enum.count(assigns.reviewers))

    ~H"""
    <.reviewer
      :for={{reviewer, idx} <- Enum.with_index(@reviewers)}
      reviewer={reviewer}
      me={@current_user}
      comma={idx < @count - 1}
    />
    """
  end

  def reviewer(%{reviewer: %{login: login}, me: %{nickname: login}} = assigns) do
    ~H"""
    <span class="text-emerald-600 italic text-sm">
      <%= username(@reviewer) %><%= if @comma, do: "," %>
    </span>
    """
  end

  def reviewer(assigns) do
    ~H"""
    <span class="text-gray-500 italic text-sm">
      <%= username(@reviewer) %><%= if @comma, do: "," %>
    </span>
    """
  end

  def toggle_reviewer_menu(assigns) do
    ~H"""
    <div class="relative">
      <.dropdown_toggle_link target={"toggle-reviewer-dropdown-#{@pull_request.id}"}>
        <.icon name="ellipsis-horizontal" class="text-gray-500 mt-1 h-5 w-5" />
      </.dropdown_toggle_link>

      <.dropdown_menu name={"toggle-reviewer-dropdown-#{@pull_request.id}"}>
        <:description>
          Add or Remove Reviewers
        </:description>

        <.dropdown_toggle_list
          name="reviewer"
          items={@members}
          ctx={"pull-request-#{@pull_request.id}"}
          value={%{pull_request_id: @pull_request.id}}
        >
          <:row :let={member}>
            <div class="flex items-center">
              <div class="w-8">
                <%= if Mrgr.Schema.PullRequest.reviewer_requested?(@pull_request, member) do %>
                  <.icon name="check" class="text-teal-700 h-5 w-5" />
                <% end %>
              </div>
              <div class="flex">
                <%= img_tag(member.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
                <%= member.login %>
              </div>
            </div>
          </:row>
        </.dropdown_toggle_list>
      </.dropdown_menu>
    </div>
    """
  end

  def pr_approval_text(assigns) do
    num = Mrgr.Schema.PullRequest.required_approvals(assigns.pull_request)
    text = "#{assigns.pull_request.approving_review_count}/#{num} approvals"

    assigns = assign(assigns, :text, text)

    ~H"""
    <%= @text %>
    """
  end

  def preview_comment(assigns) do
    ~H"""
    <div id={"comment-preview-#{@comment.id}"}>
      <div class="float-left">
        <div class="flex">
          <%= img_tag(Mrgr.Schema.Comment.author(@comment).avatar_url,
            class: "rounded-xl h-5 w-5 mr-1"
          ) %>
        </div>
      </div>
      <p class="text-gray-500 italic text-sm max-h-10">
        <%= Mrgr.Schema.Comment.body(@comment) %>
      </p>
    </div>
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <div class="flex justify-between items-center">
      <p class="truncate"><%= PullRequest.commit_message(@commit) %></p>
      <p class="text-sm text-gray-500 whitespace-nowrap">
        <%= PullRequest.commit_author_name(@commit) %>
      </p>
    </div>
    """
  end

  def render_commit(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <p><%= PullRequest.commit_message(@commit) %></p>
      <div class="flex flex-col">
        <div class="flex space-between space-x-2 divide-x divide-gray-500">
          <p class="text-sm text-gray-500 truncate">
            <%= shorten_sha(PullRequest.commit_sha(@commit)) %>
          </p>
          <p class="pl-2 text-sm text-gray-500"><%= ts(PullRequest.committed_at(@commit)) %></p>
        </div>
        <p class="text-sm text-gray-500"><%= PullRequest.commit_author_name(@commit) %></p>
      </div>
    </div>
    """
  end

  def render_comment(assigns) do
    ~H"""
    <div id={"comment-#{@comment.id}"} class="flex flex-col pt-2">
      <div class="flex flex-col">
        <.avatar member={Mrgr.Schema.Comment.author(@comment)} />
        <.aside><%= ts(@comment.posted_at, @tz) %></.aside>
      </div>
      <div class="pt-1">
        <p class="text-gray-500 italic">
          <%= Mrgr.Schema.Comment.body(@comment) %>
        </p>
      </div>
    </div>
    """
  end

  def filters(assigns) do
    ~H"""
    <div class="flex flex-col mt-2 space-y-3">
      <.aside>
        Customize your view by filtering on Author, Label, or Repository.
        <.l phx-click="delete-tab" data={[confirm: "Sure about that?"]}>
          delete tab
        </.l>
      </.aside>
      <!-- repositories -->
      <.h3>Filters</.h3>
      <div class="flex items-center">
        <.repository_icon />

        <div class="relative">
          <div
            class="flex flex-wrap -mb-px text-sm font-medium text-center items-center"
            role="tablist"
          >
            <div :for={repo <- @selected_tab.repositories} class="mr-2" role="presentation">
              <.pr_filter item={repo} />
            </div>

            <div class="relative">
              <.dropdown_toggle_link target="pr-tab-repository-dropdown">
                <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
              </.dropdown_toggle_link>

              <.dropdown_menu name="pr-tab-repository-dropdown">
                <:description>
                  Filter By Repository
                </:description>

                <.dropdown_toggle_list name="repository" items={@repos}>
                  <:row :let={repo}>
                    <div class="flex items-center">
                      <div class="w-8">
                        <%= if Mrgr.PRTab.repository_present?(@selected_tab, repo) do %>
                          <.icon name="check" class="text-teal-700 h-5 w-5" />
                        <% end %>
                      </div>
                      <%= repo.name %>
                    </div>
                  </:row>
                </.dropdown_toggle_list>
              </.dropdown_menu>
            </div>
          </div>
        </div>
      </div>
      <!-- labels -->
      <div class="flex items-center">
        <.icon name="tag" class="text-gray-400 mr-1 h-5 w-5" />

        <div class="relative">
          <div
            class="flex flex-wrap -mb-px text-sm font-medium text-center items-center"
            role="tablist"
          >
            <div :for={label <- @selected_tab.labels} class="mr-2" role="presentation">
              <.pr_filter item={label} />
            </div>

            <div class="relative">
              <.dropdown_toggle_link target="pr-tab-label-dropdown">
                <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
              </.dropdown_toggle_link>

              <.dropdown_menu name="pr-tab-label-dropdown">
                <:description>
                  Filter By Label
                </:description>

                <.dropdown_toggle_list name="label" items={@labels}>
                  <:row :let={label}>
                    <div class="flex items-center">
                      <div class="w-8">
                        <%= if Mrgr.PRTab.label_present?(@selected_tab, label) do %>
                          <.icon name="check" class="text-teal-700 h-5 w-5" />
                        <% end %>
                      </div>
                      <.badge item={label} />
                    </div>
                  </:row>
                </.dropdown_toggle_list>
              </.dropdown_menu>
            </div>
          </div>
        </div>
      </div>
      <!-- authors -->
      <div class="flex items-center">
        <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />

        <div class="flex flex-wrap -mb-px text-sm font-medium text-center items-center" role="tablist">
          <div :for={author <- @selected_tab.authors} class="mr-2" role="presentation">
            <.pr_filter item={author} />
          </div>

          <div class="relative">
            <.dropdown_toggle_link target="pr-tab-author-dropdown">
              <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
            </.dropdown_toggle_link>

            <.dropdown_menu name="pr-tab-author-dropdown">
              <:description>
                Filter By Author
              </:description>

              <.dropdown_toggle_list name="author" items={@members}>
                <:row :let={author}>
                  <div class="flex items-center">
                    <div class="w-8">
                      <%= if Mrgr.PRTab.author_present?(@selected_tab, author) do %>
                        <.icon name="check" class="text-teal-700 h-5 w-5" />
                      <% end %>
                    </div>
                    <div class="flex">
                      <%= img_tag(author.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
                      <%= author.login %>
                    </div>
                  </div>
                </:row>
              </.dropdown_toggle_list>
            </.dropdown_menu>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def tab_explanation(%{tab: %{id: "ready-to-merge"}} = assigns) do
    ~H"""
    <div class="w-3/5">
      <.aside>
        Ready to Merge pull requests have been approved (or need no approvals) and are passing CI.  Merge them!
      </.aside>
    </div>
    """
  end

  def tab_explanation(%{tab: %{id: "needs-approval"}} = assigns) do
    ~H"""
    <div class="w-3/5">
      <.aside>
        Needs Approval pull requests are passing CI but require more approvals from your team in order to merge.  Ping your team or assign more reviewers to move them along.
      </.aside>
    </div>
    """
  end

  def tab_explanation(%{tab: %{id: "fix-ci"}} = assigns) do
    ~H"""
    <div class="w-3/5">
      <.aside>
        These PRs are failing CI.  They may or may not also be fully approved, but any CI issues need to be resolved before they can be merged and should be resolved before any further approvals.
      </.aside>
    </div>
    """
  end

  def tab_explanation(%{tab: %{id: "hifs"}} = assigns) do
    ~H"""
    <div class="w-3/5">
      <.aside>
        These PRs contain changes to files marked High Impact.  Take an extra look before you merge them!
      </.aside>
    </div>
    """
  end

  def tab_explanation(%{tab: %{id: "snoozed"}} = assigns) do
    ~H"""
    <div class="w-3/5">
      <.aside>
        Snoozed PRs are hidden from your main workflow and aren't included in the badge counts.  They may be things you want to deal with later, like in a day or two, or things that are outstanding and just noise.
      </.aside>
    </div>
    """
  end

  def snooze_option(assigns) do
    ~H"""
    <.l
      id={"#{@option.id}-#{@ctx}"}
      phx_click={JS.push("snooze", value: %{snooze_id: @option.id, pr_id: @ctx})}
      class="text-teal-700 hover:text-teal-500 hover:bg-gray-50 p-2 text-sm rounded-md"
      role="menuitem"
      tabindex="-1"
    >
      <%= @option.name %>
    </.l>
    """
  end

  def action_state_emoji(%{action_state: :ready_to_merge} = assigns) do
    ~H"""
    <.tooltip>
      <:text>
        Ready to Merge
      </:text>
      🚀
    </.tooltip>
    """
  end

  def action_state_emoji(%{action_state: :needs_approval} = assigns) do
    ~H"""
    <.tooltip>
      <:text>
        Needs Approval
      </:text>
      ⚠️
    </.tooltip>
    """
  end

  def action_state_emoji(%{action_state: :fix_ci} = assigns) do
    ~H"""
    <.tooltip>
      <:text>
        Fix CI
      </:text>
      🛠
    </.tooltip>
    """
  end

  def showing_repos_text(assigns) do
    ~H"""
    <p class="text-xs">
      <%= @showing %>/<%= @total %> repos displayed.
      <.l href={~p"/repositories"} class="text-xs text-teal-700 hover:text-teal-500">Configure</.l>
    </p>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def glance_column(assigns) do
    ~H"""
    <div class={[
      "flex flex-col h-48 overflow-hidden basis-1/3",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
