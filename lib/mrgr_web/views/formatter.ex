defmodule MrgrWeb.Formatter do

  def shorten_sha(sha) do
    String.slice(sha, 1..6)
  end

  def ts(timestamp) do
    Calendar.strftime(timestamp, "%b %d, '%y %I:%M%p")
  end

end
