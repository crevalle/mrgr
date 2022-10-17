defmodule MrgrWeb.Components.Merge do
  use MrgrWeb, :component

  import Heroicons.LiveView, only: [icon: 1]

  alias Mrgr.Schema.Merge

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
    color =
      case Mrgr.Merge.tagged?(assigns.merge, assigns.current_user) do
        true ->
          "text-emerald-600"

        false ->
          "text-gray-400"
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <.icon name="at-symbol" type="solid" class={"ml-1 #{@color} h-4 w-4"} />
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <li class="p-2">
      <div class="flex flex-col space-y-1">
        <div class="flex space-between items-center">
          <p class="flex-1 truncate"><%= Merge.commit_message(@commit) %></p>
          <p class="text-sm text-gray-500"><%= ts(Merge.committed_at(@commit)) %></p>
        </div>
        <div class="flex space-between space-x-2 divide-x divide-gray-500">
          <p class="text-sm text-gray-500"><%= Merge.author_name(@commit) %></p>
          <p class="pl-2 text-sm text-gray-500"><%= shorten_sha(Merge.commit_sha(@commit)) %></p>
        </div>
      </div>
    </li>
    """
  end

  def recent_comment_sparkline(assigns) do
    data =
      assigns.comments
      |> filter_recent_comments()
      |> sparkline_data()

    line = "#b2892b"
    fill = "#fce09f"
    # Emits svg sparkline
    sparkline =
      data
      |> Contex.Sparkline.new()
      |> Contex.Sparkline.style(line_stroke: line, area_fill: fill)
      |> Contex.Sparkline.draw()

    assigns =
      assigns
      |> assign(:sparkline, sparkline)

    ~H"""
    <%= @sparkline %>
    """
  end

  def sparkline_data(comments) do
    comments
    |> bucketize()
    |> to_sparkline_data()
  end

  def bucketize(comments) do
    __MODULE__.Bucket.new(comments)
  end

  defp to_sparkline_data(bucket) do
    bucket
    |> Map.values()
    |> Enum.reverse()
  end

  defmodule Bucket do
    def new(comments) do
      bucket = empty_bucket()

      # assumes all comments fit in bucket, ie, have been filtered
      # for today
      Enum.reduce(comments, bucket, fn c, acc ->
        key = determine_key(c)

        count = Map.get(acc, key)
        Map.put(acc, key, count + 1)
      end)
    end

    def empty_bucket do
      Enum.reduce(0..23, %{}, fn k, acc ->
        Map.put(acc, k, 0)
      end)
    end

    def determine_key(comment) do
      # 0-based.  eg, something 30 mins ago is "0" hours ago
      now = DateTime.utc_now()
      then = comment.posted_at

      DateTime.diff(now, then, :hour)
    end
  end
end
