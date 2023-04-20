defmodule MrgrWeb.Components.Repository do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  alias Phoenix.LiveView.JS

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

  def policy_badges(assigns) do
    ~H"""
    <.enforce_automatically_badge policy={@policy} />
    <.default_policy_badge policy={@policy} />
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

  def enforce_automatically_badge(assigns) do
    ~H"""
    <.tooltip :if={@policy.enforce_automatically} class="pl-2">
      <.icon name="check-circle" class="text-emerald-400 hover:text-emerald-500 mr-1 h-5 w-5" />
      <:text>enforce automatically</:text>
    </.tooltip>

    <.tooltip :if={!@policy.enforce_automatically} class="pl-2">
      <.icon name="check-circle" class="text-gray-500 hover:text-emerald-500 mr-1 h-5 w-5" />
      <:text>do not enforce automatically</:text>
    </.tooltip>
    """
  end

  def default_policy_badge(assigns) do
    ~H"""
    <.tooltip :if={@policy.default} class="pl-2">
      <.icon name="star" class="text-emerald-400 hover:text-emerald-500 mr-1 h-5 w-5" />
      <:text>default policy</:text>
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

  def enforce_policy_link(assigns) do
    ~H"""
    <.l
      phx-click={JS.push("enforce-policy", value: %{policy_id: @policy_id, repo_id: @repo_id})}
      class="text-teal-700 hover:text-teal-500 hover:bg-stone-50 font-light p-3 text-sm rounded-md"
    >
      <%= render_slot(@inner_block) %>
    </.l>
    """
  end

  def compliant_repos_count(assigns) do
    compliant_count = Enum.count(assigns.compliant)
    repo_count = Enum.count(assigns.repos)

    color = if compliant_count == repo_count, do: "text-emerald-500", else: "text-red-700"

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <span class={@color}>
      <%= Enum.count(@compliant) %> / <%= Enum.count(@repos) %>
    </span>
    """
  end

  def repo_policy_name(assigns) do
    ~H"""
    <%= if Mrgr.Repository.has_policy?(@repo) do %>
      <%= if Mrgr.Repository.settings_match_policy?(@repo) do %>
        <.icon name="check" class="text-emerald-500 mr-1 h-5 w-5" />
      <% else %>
        <.icon name="exclamation-circle" class="text-red-700 mr-1 h-5 w-5" />
      <% end %>
      <span class="text-gray-500 font-light text-sm">
        <%= Mrgr.Schema.Repository.policy_name(@repo) %>
      </span>
    <% else %>
      <p class="text-gray-500 font-light texts-sm italic">no policy</p>
    <% end %>
    """
  end
end
