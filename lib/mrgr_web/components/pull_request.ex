defmodule MrgrWeb.Components.PullRequest do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  alias Mrgr.Schema.PullRequest
  alias Phoenix.LiveView.JS

  def pull_request_detail(%{attr: "comments"} = assigns) do
    ~H"""
    <.pull_request_detail_content>
      <:title>
        Comments (<%= Enum.count(@pull_request.comments) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_comment :for={comment <- @pull_request.comments} comment={comment} tz={@timezone} />
      </div>
    </.pull_request_detail_content>
    """
  end

  def pull_request_detail(%{attr: "commits"} = assigns) do
    ~H"""
    <.pull_request_detail_content>
      <:title>
        Commits (<%= Enum.count(@pull_request.commits) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_commit :for={commit <- @pull_request.commits} commit={commit} tz={@timezone} />
      </div>
    </.pull_request_detail_content>
    """
  end

  def pull_request_detail(%{attr: "files-changed"} = assigns) do
    ~H"""
    <.pull_request_detail_content>
      <:title>
        Files Changed (<%= Enum.count(@pull_request.files_changed) %>)
      </:title>
      <div class="flex flex-col space-y-0 leading-tight">
        <.changed_file
          :for={f <- @pull_request.files_changed}
          filename={f}
          alerts={@pull_request.repository.file_change_alerts}
        />
      </div>
    </.pull_request_detail_content>
    """
  end

  def pull_request_detail_content(assigns) do
    ~H"""
    <div class="flex flex-col space-y-6 bg-white rounded-md">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between items-start">
          <.h3>
            <%= render_slot(@title) %>
          </.h3>
          <.close_detail_pane phx_click={JS.push("hide-detail")} />
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def changed_file(assigns) do
    matching_alert =
      Enum.find(
        assigns.alerts,
        &Mrgr.FileChangeAlert.pattern_matches_filename?(assigns.filename, &1)
      )

    color =
      case matching_alert do
        nil -> "transparent"
        alert -> alert.color
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <div style={"border-color: #{@color};"} class="border-l-2"><pre><%= @filename %></pre></div>
    """
  end

  def recent_comment_count(assigns) do
    recent_comments = filter_recent_comments(assigns.comments)

    assigns =
      assigns
      |> assign(:recent_comments, recent_comments)

    ~H"""
    <.icon name="location-marker" type="solid" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
    <%= Enum.count(@comments) %> comments <%= Enum.count(@recent_comments) %> in last 24 hours
    """
  end

  def filter_recent_comments(comments) do
    Enum.filter(comments, &recent?/1)
  end

  defp recent?(comment) do
    threshold = DateTime.add(DateTime.utc_now(), -24, :hour)

    case DateTime.compare(comment.posted_at, threshold) do
      :gt -> true
      _stale_mf -> false
    end
  end

  def reviewers(%{reviewers: []} = assigns) do
    ~H"""
    <span class="text-gray-500 italic text-sm">none</span>
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
              <div class="w-8 text-blue-400 ">
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

  def pr_approval_badge(%{fully_approved: true} = assigns) do
    ~H"""
    <p class="flex">
      <.icon name="check" class="text-sky-600 mr-1 h-5 w-5" /> Ready to merge
    </p>
    """
  end

  def pr_approval_badge(%{fully_approved: false} = assigns) do
    ~H"""
    <p class="flex">
      <.icon name="exclamation-circle" class="text-yellow-800 mr-1 h-5 w-5" /> Awaiting approvals
    </p>
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

  def ci_status(%{ci_status: "success"} = assigns) do
    ~H"""
    <p class="flex">
      <.icon name="check-circle" class="text-sky-600 mr-1 h-5 w-5" /> CI Passing
    </p>
    """
  end

  def ci_status(%{ci_status: "running"} = assigns) do
    ~H"""
    <p class="flex">
      <.icon name="wrench" class="text-gray-500 mr-1 h-5 w-5" /> CI Running
    </p>
    """
  end

  def ci_status(%{ci_status: "failure"} = assigns) do
    ~H"""
    <p class="flex">
      <.icon name="exclamation-circle" class="text-yellow-800 mr-1 h-5 w-5" /> Fix CI
    </p>
    """
  end

  def ci_status(assigns) do
    ~H"""
    <p class="flex">
      <.icon name="question-mark-circle" class="text-gray-500 mr-1 h-5 w-5" /> CI Status Unknown
    </p>
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <div class="flex flex-col">
      <p class="truncate"><%= PullRequest.commit_message(@commit) %></p>
      <div class="flex space-between space-x-2 divide-x divide-gray-500">
        <p class="text-sm text-gray-500"><%= PullRequest.commit_author_name(@commit) %></p>
        <p class="pl-2 text-sm text-gray-500"><%= ts(PullRequest.committed_at(@commit)) %></p>
        <p class="pl-2 text-sm text-gray-500 truncate">
          <%= shorten_sha(PullRequest.commit_sha(@commit)) %>
        </p>
      </div>
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
    <div class="flex flex-col pt-2">
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

  def tab_detail_content(%{tab: "recent"} = assigns) do
    ~H"""
    you've chosen the recent tab
    """
  end

  def tab_detail_content(%{tab: "two-weeks"} = assigns) do
    ~H"""
    you've chosen the two weeks tab
    """
  end

  def tab_detail_content(assigns) do
    ~H"""
    I have ants in my pants
    """
  end
end
