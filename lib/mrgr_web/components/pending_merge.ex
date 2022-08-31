defmodule MrgrWeb.Component.PendingMerge do
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
          <.file_alert_badge bg="bg-green-100" text="text-green-800">migration</.file_alert_badge>
        <% end %>

        <%= if router_changed?(@merge) do %>
          <.file_alert_badge bg="bg-blue-100" text="text-blue-800">router</.file_alert_badge>
        <% end %>

        <%= if dependencies_changed?(@merge) do %>
          <.file_alert_badge bg="bg-yellow-100" text="text-yellow-800">dependencies</.file_alert_badge>
        <% end %>

        <%= for alert <- Mrgr.FileChangeAlert.for_merge(@merge) do %>
          <.file_alert_badge bg="bg-gray-100" text="text-gray-800"><%= alert.badge_text %></.file_alert_badge>
        <% end %>
      </div>
    """
  end

  def file_alert_badge(%{bg: _, text: _} = assigns) do
    ~H"""
      <p class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{@bg} #{@text}"}>
        <%= render_slot(@inner_block) %>
      </p>
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
