defmodule MrgrWeb.Components.Live.PendingPullRequestItem do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  defp highlighted_color(true), do: "border-teal-500"
  defp highlighted_color(false), do: "border-gray-200"

  def repo_text_color(true), do: "text-blue-600"
  def repo_text_color(false), do: "text-gray-400"
end
