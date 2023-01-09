defmodule MrgrWeb.Formatter do
  @thirty_days 2_592_000
  @fourteen_days 1_209_600
  @seven_days 604_800
  @five_days 432_000
  @three_days 259_200
  @one_day 86_400

  def shorten_sha(sha) do
    String.slice(sha, 0..6)
  end

  def ts(nil, _timezone), do: nil

  def ts(timestamp, timezone) do
    case DateTime.shift_zone(timestamp, timezone) do
      {:ok, new_timestamp} -> ts(new_timestamp)
      {:error, _busted} -> ts(timestamp)
    end
  end

  def ts(timestamp) do
    # 3:14pm Mar 3, '22

    format =
      case timestamp.year == Mrgr.DateTime.now().year do
        true -> "%-I:%M%p %b %d"
        false -> "%-I:%M%p %b %d, '%y"
      end

    Calendar.strftime(timestamp, format)
  end

  def ago(nil), do: nil

  def ago(timestamp) do
    seconds = timestamp_diff_seconds(timestamp)

    case seconds do
      s when s < 60 ->
        "<1m"

      s when s < 3600 ->
        "#{floor(s / 60)}m"

      s when s < @one_day ->
        "#{floor(s / 3600)}h"

      # 2 weeks
      s when s < @fourteen_days ->
        "#{floor(s / @one_day)}d"

      # 8 weeks
      s when s < 4_838_400 ->
        "#{floor(s / @seven_days)}w"

      # hack because 8 weeks does not exactly equal 2 months
      s when s < 5_184_000 ->
        %{month: m} = DateTime.utc_now()
        timestamp.month
        "#{m - timestamp.month}mo"

      # less than 2 years, roughly
      s when s < 62_208_000 ->
        "#{floor(s / @thirty_days)}mo"

      # 2 years or more
      s ->
        "#{round(s / (@thirty_days * 12))}y"
    end
  end

  def timestamp_diff_seconds(timestamp) do
    DateTime.diff(DateTime.utc_now(), timestamp)
  end

  def uhoh_color(%DateTime{} = dt) do
    DateTime.utc_now()
    |> DateTime.diff(dt)
    |> uhoh_color()
  end

  def uhoh_color(seconds) when seconds >= @five_days, do: "text-red-500"
  def uhoh_color(seconds) when seconds >= @seven_days, do: "text-red-600"
  def uhoh_color(seconds) when seconds >= @three_days, do: "text-red-700"
  def uhoh_color(_seconds), do: "text-gray-500"

  def ref("refs/heads/" <> name), do: name

  def render_struct(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> render_map()
  end

  def render_map(map) when is_map(map) do
    Jason.encode!(map, pretty: true)
  end

  def tf(true), do: "🟢"
  def tf(false), do: "⭕️"

  def quote_if_present(nil), do: nil
  def quote_if_present(str), do: ~s("#{str}")

  def shorten(text, length \\ 50) do
    "#{String.slice(text, 1..length)}..."
  end

  def selected_border(true), do: "border-teal-500"
  def selected_border(false), do: "border-gray-200"

  # used on trs to prevent overlapping borders
  def selected_outline(true), do: "outline outline-1 outline-teal-500"
  def selected_outline(false), do: "border border-gray-200"

  def username(nil), do: nil
  def username(%{login: login}), do: "@#{login}"

  def usernames(members) do
    members
    |> Enum.map(&username/1)
    |> Enum.sort()
    |> Enum.join(", ")
  end
end
