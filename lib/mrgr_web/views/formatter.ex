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

  def ago(timestamp, local_timezone) do
    # TODO: make this something like 3h, 2d.  but it should update constantly as time passes.
    # for now, just pass through to ordinary long form timestamp formatting
    #
    ts(timestamp, local_timezone)
  end

  def ref("refs/heads/" <> name), do: name
end
