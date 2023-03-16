defmodule MrgrWeb.ChangelogLive do
  use MrgrWeb, :live_view

  import MrgrWeb.Components.Changelog

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    if connected?(socket) do
      moment = Mrgr.DateTime.now()

      pull_requests = fetch_prs(socket.assigns.current_user, moment, socket.assigns.timezone)

      socket
      |> put_title("Changelog")
      |> assign(:moment, moment)
      # need the page variable to make the infinite scroll js work
      |> assign(:page, 1)
      |> stream(:pull_requests, pull_requests, dom_id: &dom_id/1)
      |> ok()
    else
      ok(socket)
    end
  end

  defp dom_id({date, _prs}), do: "week-#{format_week(date)}"

  def handle_event("load-more", _params, %{assigns: assigns} = socket) do
    new_moment =
      assigns.moment
      |> Mrgr.DateTime.previous_quarter()

    socket
    |> assign(moment: new_moment)
    # page variable just used for infinite scroll mechanism, not for actual data loading
    |> assign(page: assigns.page + 1)
    |> load_prs()
    |> noreply()
  end

  def fetch_prs(current_user, moment, timezone) do
    starting_dt = Mrgr.DateTime.beginning_of_quarter(moment)

    ending_dt = end_of_window(moment)

    current_user
    |> Mrgr.PullRequest.closed_between(starting_dt, ending_dt)
    |> bucketize(starting_dt, ending_dt, timezone)
  end

  defp end_of_window(moment) do
    now = Mrgr.DateTime.now()
    later = Mrgr.DateTime.end_of_quarter(moment)

    # on first load, we're in the middle of the quarter, so don't show
    # future weeks in the quarter.  top week should be the current week
    case Mrgr.DateTime.in_the_future?(later) do
      true ->
        now

      false ->
        later
    end
  end

  def load_prs(%{assigns: assigns} = socket) do
    prs = fetch_prs(assigns.current_user, assigns.moment, assigns.timezone)
    stream_insert_list(socket, :pull_requests, prs)
  end

  # i suspect this will be deprecated soon in a phoenix update
  def stream_insert_list(socket, key, items) when is_list(items) do
    Enum.reduce(items, socket, fn item, s ->
      stream_insert(s, key, item)
    end)
  end

  def bucketize([], _starting, _ending, _timezone) do
    []
  end

  def bucketize(prs, starting_dt, ending_dt, timezone) do
    earliest_week = beginning_of_week_date(starting_dt, timezone)
    latest_week = beginning_of_week_date(ending_dt, timezone)

    # in days, should be either 0 or multiples of 7
    diff = Date.diff(latest_week, earliest_week)

    weeks = round(diff / 7)

    bucket =
      Enum.reduce(0..weeks, %{}, fn n, acc ->
        # negative because our diff has latest as first arg
        key = Date.add(latest_week, -n * 7)
        Map.put(acc, key, [])
      end)

    Enum.reduce(prs, bucket, fn pr, acc ->
      key = beginning_of_week_date(pr.merged_at, timezone)

      prs = Map.get(acc, key)

      updated = [pr | prs]

      Map.put(acc, key, updated)
    end)
    |> map_to_list()
    |> Enum.sort_by(&the_date/1, Date)
    |> Enum.reverse()
  end

  defp map_to_list(bucket) do
    # %{~D[] => [%PR{}] } => [{~D[], [%PR{}]}]
    Enum.map(bucket, fn {k, v} ->
      {k, v}
    end)
  end

  defp the_date({date, _prs}), do: date

  defp beginning_of_week_date(dt, timezone) do
    dt
    |> DateTime.shift_zone!(timezone)
    |> DateTime.to_date()
    |> Date.beginning_of_week()
  end
end
