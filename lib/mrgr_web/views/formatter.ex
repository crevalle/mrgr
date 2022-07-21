defmodule MrgrWeb.Formatter do
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
    seconds = DateTime.diff(DateTime.utc_now(), timestamp)

    case seconds do
      s when s < 60 ->
        "<1m"

      s when s < 3600 ->
        "#{floor(s / 60)}m"

      s when s < 86400 ->
        "#{floor(s / 3600)}h"

      # 2 weeks
      s when s < 1_209_600 ->
        "#{floor(s / 86400)}d"

      # 8 weeks
      s when s < 4_838_400 ->
        "#{floor(s / (86400 * 7))}w"

      # hack because 8 weeks does not exactly equal 2 months
      s when s < 5_184_000 ->
        %{month: m} = DateTime.utc_now()
        timestamp.month
        "#{m - timestamp.month}mo"

      # less than 2 years, roughly
      s when s < 62_208_000 ->
        "#{floor(s / (86400 * 30))}mo"

      # 2 years or more
      s ->
        "#{round(s / (86400 * 30 * 12))}y"
    end
  end

  def ref("refs/heads/" <> name), do: name
end
