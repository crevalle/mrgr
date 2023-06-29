defmodule MrgrWeb.Components.Repository do
  use MrgrWeb, :component

  import MrgrWeb.Components.Core

  def possible_merge_badges(assigns) do
    shape = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full"

    assigns =
      assigns
      |> assign(:shape, shape)

    ~H"""
    <div class="flex justify-center space-x-2">
      <span :if={@settings.merge_commit_allowed} class={"#{@shape} bg-pink-100"}>merge</span>
      <span :if={@settings.rebase_merge_allowed} class={"#{@shape} bg-blue-100"}>rebase</span>
      <span :if={@settings.squash_merge_allowed} class={"#{@shape} bg-green-100"}>squash</span>
    </div>
    """
  end

  def approving_review_count(%{count: count} = assigns) when is_integer(count) and count > 0 do
    ~H"""
    <span class=""><%= @count %></span>
    """
  end

  def approving_review_count(assigns) do
    ~H"""
    <span class="text-gray-400">-</span>
    """
  end

  def repo_forked_badge(assigns) do
    ~H"""
    <.tooltip :if={@parent.name} class="pl-2">
      <.icon name="share" class="text-gray-400 hover:text-gray-500 mr-1 h-5 w-5" />
      <:text>
        forked from <%= @parent.name_with_owner %>
      </:text>
    </.tooltip>
    """
  end

  def lock(%{bool: true} = assigns) do
    ~H"""
    <.tooltip>
      <.icon name="lock-closed" class="text-emerald-400 hover:text-emerald-500 mr-1 h-5 w-5" />
      <:text>Private</:text>
    </.tooltip>
    """
  end

  def lock(%{bool: false} = assigns) do
    ~H"""
    <.tooltip>
      <.icon name="lock-open" class="text-gray-400 hover:text-gray-500 mr-1 h-5 w-5" />
      <:text>Public</:text>
    </.tooltip>
    """
  end
end
