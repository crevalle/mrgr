defmodule MrgrWeb.Components.Live.Sparkline do
  use MrgrWeb, :live_component

  def update(assigns, socket) do
    recent_comments = filter_recent(assigns.comments)
    recent_commits = filter_recent(assigns.commits)

    data = sparkline_data(recent_comments ++ recent_commits)

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
      <div class="">
        <%= @sp %>
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
    sorted_keys =
      Map.keys(bucket)
      |> Enum.sort()
      |> Enum.reverse()

    sorted_keys
    |> Enum.map(&Map.get(bucket, &1))
  end

  def filter_recent(interesting_thing) do
    Enum.filter(interesting_thing, &recent?/1)
  end

  defp recent?(interesting_thing) do
    threshold = DateTime.add(DateTime.utc_now(), -24, :hour)

    interesting_thing
    |> Mrgr.DateTime.happened_at()
    |> DateTime.compare(threshold)
    |> case do
      :gt -> true
      _stale_mf -> false
    end
  end

  defmodule Bucket do
    def new(things) do
      bucket = empty_bucket()

      # assumes all comments fit in bucket, ie, have been filtered
      # for today
      Enum.reduce(things, bucket, fn c, acc ->
        key = determine_key(c)

        count = Map.get(acc, key, 0)
        Map.put(acc, key, count + 1)
      end)
    end

    def empty_bucket do
      Enum.reduce(0..23, %{}, fn k, acc ->
        Map.put(acc, k, 0)
      end)
    end

    def determine_key(interesting_thing) do
      # 0-based.  eg, something 30 mins ago is "0" hours ago
      now = DateTime.utc_now()
      then = Mrgr.DateTime.happened_at(interesting_thing)

      DateTime.diff(now, then, :hour)
    end
  end
end
