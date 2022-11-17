defmodule MrgrWeb.Components.Live.PullRequestListItem do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  def repo_text_color(true), do: "text-blue-600"
  def repo_text_color(false), do: "text-gray-400"
end
