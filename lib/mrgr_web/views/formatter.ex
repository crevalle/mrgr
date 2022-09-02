defmodule MrgrWeb.Formatter do
  @thirty_days 2_592_000
  @fourteen_days 1_209_600
  @twelve_days 1_036_800
  @eleven_days 950_400
  @nine_days 777_600
  @seven_days 604_800
  @five_days 432_000
  @four_days 345_600
  @three_days 259_200
  @one_day 86_400

  def shorten_sha(sha) do
    String.slice(sha, 0..6)
  end

  def ts(nil, _), do: nil

  def ts(timestamp, local_timezone) do
    case DateTime.shift_zone(timestamp, local_timezone) do
      {:ok, new_timestamp} -> ts(new_timestamp)
      {:error, _busted} -> ts(timestamp)
    end
  end

  def ts(timestamp) do
    Calendar.strftime(timestamp, "%I:%M%p %b %d, '%y")
  end

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
  def uhoh_color(seconds), do: "text-gray-500"

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
end
