defmodule MrgrWeb.Components.PullRequest do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  alias Mrgr.Schema.PullRequest
  alias Phoenix.LiveView.JS

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

  def controversy_badge(assigns) do
    ~H"""
    <div class="mb-1">
      <.badge item={%{name: "Controversial", color: "#edbd45"}} />
    </div>
    """
  end

  def changed_file_list(assigns) do
    ~H"""
    <div class="flex flex-col space-y-0 leading-tight">
      <.changed_file :for={f <- @files_changed} filename={f} hifs={@hifs} />
    </div>
    """
  end

  def changed_file(assigns) do
    matching_file =
      Enum.find(
        assigns.hifs,
        &Mrgr.HighImpactFileRule.pattern_matches_filename?(assigns.filename, &1)
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
        <%= img_tag(Mrgr.Schema.Comment.author(@comment).avatar_url,
          class: "rounded-xl h-5 w-5 mr-1"
        ) %>
      </div>
      <div class="comment-preview">
        <%= md(Mrgr.Schema.Comment.body(@comment)) %>
      </div>
    </div>
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <div class="flex justify-between items-center w-full">
      <p class="truncate"><%= PullRequest.commit_message(@commit) %></p>
      <p class="text-sm text-gray-500 whitespace-nowrap">
        <%= author_handle(@commit) %>
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
          <p class="pl-2 text-sm text-gray-500"><%= ts(Mrgr.DateTime.happened_at(@commit)) %></p>
        </div>
        <p class="text-sm text-gray-500"><%= author_handle(@commit) %></p>
      </div>
    </div>
    """
  end

  def render_comment(assigns) do
    ~H"""
    <div id={"comment-#{@comment.id}"} class="flex flex-col pt-2">
      <div class="flex flex-col">
        <div class="flex space-x-1 items-center">
          <.avatar member={Mrgr.Schema.Comment.author(@comment)} />
          <.link_to_comment url={Mrgr.Schema.Comment.url(@comment)} />
        </div>
        <.aside><%= ts(@comment.posted_at, @tz) %></.aside>
      </div>
      <div class="pt-1">
        <p class="text-gray-500 italic">
          <%= md(Mrgr.Schema.Comment.body(@comment)) %>
        </p>
      </div>
    </div>
    """
  end

  def snooze_option(assigns) do
    ~H"""
    <.l
      id={"#{@option.id}-#{@ctx}"}
      phx-click={JS.push("snooze", value: %{snooze_id: @option.id, pr_id: @ctx})}
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
      <.l href={~p"/repositories"} class="text-xs">Configure</.l>
    </p>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def glance_column(assigns) do
    ~H"""
    <div class={[
      "glance-column",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def glance_detail_link(assigns) do
    ~H"""
    <.link
      patch={@href}
      class="flex items-center text-teal-700 hover:text-teal-500 hover:cursor-pointer"
    >
      <h6><%= render_slot(@inner_block) %></h6>
      <.icon name="chevron-right" class="h-4 w-4" />
    </.link>
    """
  end

  def title(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <.l href={@href} target="_blank">
        <div class="flex items-center space-x-1 text-teal-700 hover:text-teal-500">
          <.h3><%= @title %></.h3>
          <.icon name="arrow-top-right-on-square" class="flex-shrink-0 h-5 w-5" />
        </div>
      </.l>
      <%= if @draft do %>
        <span class="text-gray-400">[draft]</span>
      <% else %>
        <.action_state_emoji :if={@show_action_state_emoji} action_state={@action_state} />
      <% end %>
    </div>
    """
  end

  def labels(assigns) do
    ~H"""
    <div class="mt-2 flex flex-wrap items-center space-x text-sm text-gray-500 sm:mt-0">
      <.icon name="tag" class="text-gray-400 h-5 w-5" />
      <div class="flex space-x-2">
        <.badge :for={label <- @labels} item={label} />
      </div>
    </div>
    """
  end

  def repository_and_branch(assigns) do
    ~H"""
    <div class="flex space-x">
      <.repository_icon />
      <p class="text-sm italic font-light text-gray-400"><%= @repository.name %>/<%= @branch %></p>
    </div>
    """
  end

  def byline(assigns) do
    ~H"""
    <p class="text-sm font-light text-gray-400">
      by @<%= @author %>
    </p>
    """
  end

  def line_diff(assigns) do
    ~H"""
    <p class="text-sm flex items-center space-x-1">
      <span class="text-green-600">+<%= number_with_delimiter(@additions) %></span>
      <span class="text-red-400">-<%= number_with_delimiter(@deletions) %></span>
    </p>
    """
  end

  def link_to_comment(%{url: nil} = assigns), do: ~H[]

  def link_to_comment(assigns) do
    ~H"""
    <.l href={@url} target="_blank" class="text-gray-400">
      <.icon name="arrow-top-right-on-square" class="h-4 w-4" />
    </.l>
    """
  end
end
