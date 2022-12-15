defmodule MrgrWeb.Live.AnalyticsBox do
  use MrgrWeb, :live_view

  alias __MODULE__.DasBucket

  def render(assigns) do
    ~H"""
      <div class="flex flex-col border-gray-300">
        <.h3>Weekly Analytics</.h3>
        <div class="flex items-center mt-2 space-y-2">
          <div class="flex flex-col">
            <p>Closed PRs</p>
            <p>Average Time Open</p>
          </div>
          <div class="flex flex-col ml-2">
            <p><%= @closed_pr_sparkline %></p>
            <p><%= @time_open_sparkline %></p>
          </div>
          <div class="flex flex-col ml-2">
            <p><%= closed_this_week(@bucket) %></p>
            <p><.to_days hours={@time_open_this_week} /></p>
          </div>
        </div>
      </div>
    """
  end

  def mount(_session, params, socket) do
    if connected?(socket) do
      installation_id = params["installation_id"]

      # will be off by the timezone, but oh well
      d = Date.utc_today()

      twelve_weeks_ago =
        d |> Date.add(-84) |> Date.beginning_of_week() |> DateTime.new!(~T[00:00:00])

      closed_prs = Mrgr.PullRequest.closed_for_installation(installation_id, twelve_weeks_ago)

      bucket =
        DasBucket.new()
        |> DasBucket.fill(closed_prs)

      socket
      |> assign(:installation_id, installation_id)
      |> assign(:bucket, bucket)
      |> assign(:closed_pr_sparkline, generate_closed_pr_sparkline(bucket))
      |> assign(:time_open_sparkline, generate_time_open_sparkline(bucket))
      |> assign(:time_open_this_week, time_open_this_week(bucket))
      |> ok()
    else
      ok(socket)
    end
  end

  def closed_this_week(bucket) do
    bucket
    |> DasBucket.to_sparkline_data()
    |> hd()
    |> Map.get(:count)
  end

  def generate_closed_pr_sparkline(bucket) do
    line = "#b2892b"
    fill = "#fce09f"

    data =
      bucket
      |> DasBucket.to_sparkline_data()
      |> Enum.map(fn %{count: count} -> count end)

    # [
    # %{count: 2, time_open: -768},
    # %{count: 2, time_open: -1104},

    data
    |> Contex.Sparkline.new()
    |> Contex.Sparkline.style(line_stroke: line, area_fill: fill)
    |> Contex.Sparkline.draw()
  end

  def generate_time_open_sparkline(bucket) do
    line = "#b2892b"
    fill = "#fce09f"

    data =
      bucket
      |> DasBucket.to_sparkline_data()
      |> Enum.map(&average_time_open/1)

    data
    |> Contex.Sparkline.new()
    |> Contex.Sparkline.style(line_stroke: line, area_fill: fill)
    |> Contex.Sparkline.draw()
  end

  def time_open_this_week(bucket) do
    bucket
    |> DasBucket.to_sparkline_data()
    |> hd()
    |> average_time_open()
  end

  def average_time_open(%{count: count, time_open: time_open}) do
    Float.round(time_open / count, 2)
  end

  defmodule DasBucket do
    # 12-week bucket

    def new() do
      weeks = 12

      Enum.reduce(0..weeks, %{}, fn d, acc ->
        key = determine_key(d)

        stats = %{
          count: :rand.uniform(10),
          time_open: 0
        }

        Map.put(acc, key, stats)
      end)
    end

    def fill(bucket, prs) do
      Enum.reduce(prs, bucket, fn pr, acc ->
        key = determine_key(pr)

        stats = acc[key]

        time_open = Mrgr.PullRequest.time_open(pr)

        updated = %{count: stats.count + 1, time_open: stats.time_open + time_open}
        Map.put(acc, key, updated)
      end)
    end

    def determine_key(0) do
      Date.utc_today()
      |> Date.beginning_of_week()
    end

    def determine_key(weeks_ago) when is_integer(weeks_ago) do
      days = 7 * weeks_ago

      Date.utc_today()
      |> Date.beginning_of_week()
      |> Date.add(-days)
    end

    def determine_key(pull_request) do
      pull_request.merged_at
      |> DateTime.to_date()
      |> Date.beginning_of_week()
    end

    # [
    # %{count: 2, time_open: -768},
    # %{count: 2, time_open: -1104},
    # %{count: 4, time_open: -744},
    # %{count: 10, time_open: 264},
    # %{count: 6, time_open: 888},
    # %{count: 6, time_open: 2712},
    # %{count: 5, time_open: 2544},
    # %{count: 6, time_open: 3792},
    # %{count: 10, time_open: 7704},
    # %{count: 6, time_open: 5064},
    # %{count: 11, time_open: 12168},
    # %{count: 6, time_open: 7416},
    # %{count: 10, time_open: 15912}
    # ]
    def to_sparkline_data(bucket) do
      sorted_keys =
        bucket
        |> Map.keys()
        |> Enum.sort_by(& &1, Date)

      sorted_keys
      |> Enum.map(&Map.get(bucket, &1))
      |> Enum.reverse()
    end
  end
end
