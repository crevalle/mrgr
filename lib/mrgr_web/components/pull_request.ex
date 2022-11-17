defmodule MrgrWeb.Components.PullRequest do
  use MrgrWeb, :component

  alias Mrgr.Schema.PullRequest

  def changed_file_li(assigns) do
    matching_alert =
      Enum.find(
        assigns.alerts,
        &Mrgr.FileChangeAlert.pattern_matches_filename?(assigns.filename, &1)
      )

    color =
      case matching_alert do
        nil -> "transparent"
        alert -> alert.bg_color
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
      <li style={"border-color: #{@color};"} class="pl-2 border-l-2"><pre><%= @filename %></pre></li>
    """
  end

  def recent_comment_count(assigns) do
    recent_comments = filter_recent_comments(assigns.comments)

    assigns =
      assigns
      |> assign(:recent_comments, recent_comments)

    ~H"""
      <.icon name="location-marker" type="solid" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
      <%= Enum.count(@comments) %> comments
      <%= Enum.count(@recent_comments) %> in last 24 hours
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

  def me_tag(assigns) do
    tagged = Mrgr.PullRequest.tagged?(assigns.pull_request, assigns.current_user)

    assigns =
      assigns
      |> assign(:tagged, tagged)

    ~H"""
      <.icon :if={@tagged} name="at-symbol" type="solid" class={"mr-1 text-emerald-600 h-4 w-4"} />
    """
  end

  def pr_approval_badge(assigns) do
    fully_approved = Mrgr.PullRequest.fully_approved?(assigns.pull_request)

    assigns =
      assigns
      |> assign(:fully_approved, fully_approved)

    ~H"""
    <%= if @fully_approved do %>
      <p class="flex">
        <.icon name="check" class="text-sky-600 mr-1 h-5 w-5" />
        Ready to merge
      </p>
    <% else %>
      <p class="flex">
        <.icon name="exclamation-circle" class="text-yellow-800 mr-1 h-5 w-5" />
        Awaiting approvals
      </p>
    <% end %>
    """
  end

  def pr_approval_text(assigns) do
    text =
      case Mrgr.Schema.PullRequest.required_approvals(assigns.pull_request) do
        0 ->
          "no approvals required for this repo"

        num ->
          "(#{Mrgr.PullRequest.approving_reviews(assigns.pull_request)}/#{num}) approvals"
      end

    assigns = assign(assigns, :text, text)

    ~H"""
    <%= @text %>
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <li class="p-2">
      <div class="flex flex-col ">
        <div class="flex space-between items-center">
          <p class="flex-1 truncate"><%= PullRequest.commit_message(@commit) %></p>
          <p class="text-sm text-gray-500"><%= ts(PullRequest.committed_at(@commit)) %></p>
        </div>
        <div class="flex space-between space-x-2 divide-x divide-gray-500">
          <p class="text-sm text-gray-500"><%= PullRequest.author_name(@commit) %></p>
          <p class="pl-2 text-sm text-gray-500"><%= shorten_sha(PullRequest.commit_sha(@commit)) %></p>
        </div>
      </div>
    </li>
    """
  end
end