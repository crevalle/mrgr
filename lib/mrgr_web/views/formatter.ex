defmodule MrgrWeb.Formatter do
  def shorten_sha(sha) do
    String.slice(sha, 0..6)
  end

  def ts(timestamp, local_timezone) do
    case DateTime.shift_zone(timestamp, local_timezone) do
      {:ok, new_timestamp} -> ts(new_timestamp)
      {:error, _busted} -> ts(timestamp)
    end
  end

  def ts(timestamp) do
    Calendar.strftime(timestamp, "%b %d, '%y %I:%M%p")
  end
end
