defmodule MrgrWeb.Components.PendingMerge do
  use MrgrWeb, :component

  alias Mrgr.Schema.Merge

  def preview_commit(assigns) do
    ~H"""
    <li class="p-2">
      <div class="flex flex-col space-y-1">
        <div class="flex space-between items-center">
          <p class="flex-1 truncate"><%= Merge.commit_message(@commit) %></p>
          <p class="text-sm text-gray-500"><%= ts(Merge.committed_at(@commit)) %></p>
        </div>
        <div class="flex space-between space-x-2 divide-x divide-gray-500">
          <p class="text-sm text-gray-500"><%= Merge.author_name(@commit) %></p>
          <p class="pl-2 text-sm text-gray-500"><%= shorten_sha(Merge.commit_sha(@commit)) %></p>
        </div>
      </div>
    </li>
    """
  end

  def change_badges(assigns) do
    ~H"""
      <div class="mt-2 flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
        <%= if has_migration?(@merge) do %>
          <.badge bg="bg-green-100" text="text-gray-800">migration</.badge>
        <% end %>

        <%= if router_changed?(@merge) do %>
          <.badge bg="bg-blue-100" text="text-gray-800">router</.badge>
        <% end %>

        <%= if dependencies_changed?(@merge) do %>
          <.badge bg="bg-yellow-100" text="text-gray-800">dependencies</.badge>
        <% end %>

        <%= for alert <- Mrgr.FileChangeAlert.for_merge(@merge) do %>
          <.badge bg={alert.bg_color}><%= alert.badge_text %></.badge>
        <% end %>
      </div>
    """
  end

  def badge(%{bg: _} = assigns) do
    ~H"""
      <span style={"background-color: #{@bg}; color: rgb(75 85 99);"} class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full"}>
        <%= render_slot(@inner_block) %>
      </span>
    """
  end

  def has_migration?(%{files_changed: files}) do
    Enum.any?(files, fn f ->
      String.starts_with?(f, "priv/repo/migrations")
    end)
  end

  def router_changed?(%{files_changed: files}) do
    Enum.any?(files, fn f ->
      String.ends_with?(f, "router.ex")
    end)
  end

  def dependencies_changed?(%{files_changed: files}) do
    Enum.any?(files, fn f ->
      String.ends_with?(f, "mix.lock")
    end)
  end
end
