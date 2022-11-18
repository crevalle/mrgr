defmodule MrgrWeb.Components.Live.PullRequestListItem do
  use MrgrWeb, :live_component
  use Mrgr.PubSub.Event

  import MrgrWeb.Components.PullRequest

  def repo_text_color(true), do: "text-blue-600"
  def repo_text_color(false), do: "text-gray-400"

  def item_border_color(item, selected) do
    case Mrgr.PullRequest.snoozed?(item) do
      true ->
        case selected do
          true -> "border-blue-500"
          false -> "border-blue-200"
        end

      false ->
        case selected do
          true -> "border-teal-500"
          false -> "border-gray-200"
        end
    end
  end
end
