defmodule MrgrWeb.Components.Live.CommentSparkline do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    recent_comments = filter_recent_comments(assigns.comments)
    data = sparkline_data(recent_comments)

    line = "#b2892b"
    fill = "#fce09f"
    # Emits svg sparkline
    sparkline =
      data
      |> Contex.Sparkline.new()
      |> Contex.Sparkline.style(line_stroke: line, area_fill: fill)
      |> Contex.Sparkline.draw()

    socket
    |> assign(assigns)
    |> assign(:recent_comments, recent_comments)
    |> assign(:sp, sparkline)
    |> ok()
  end

  def render(assigns) do
    ~H"""
      <div class="flex flex-col">
        <%= @sp %>
        <p class="text-gray-500"><span class="font-bold"><%= Enum.count(@recent_comments) %></span> in last 24 hours</p>
        <p class="text-gray-500"><span class="font-bold"><%= Enum.count(@comments) %></span> comments total</p>
      </div>
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
    Map.values(bucket)
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
