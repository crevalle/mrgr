defmodule MrgrWeb.Component.PendingMerge do
  use Phoenix.Component

  def change_badges(assigns) do
    ~H"""
      <div class="mt-2 flex items-center space-x-2 text-sm text-gray-500 sm:mt-0 sm:ml-6">
        <%= if has_migration?(assigns.merge) do %>
          <.badge bg="bg-green-100" text="text-green-800">migration</.badge>
        <% end %>

        <%= if router_changed?(assigns.merge) do %>
          <.badge bg="bg-blue-100" text="text-blue-800">router</.badge>
        <% end %>

        <%= if dependencies_changed?(assigns.merge) do %>
          <.badge bg="bg-yellow-100" text="text-yellow-800">dependencies</.badge>
        <% end %>
      </div>
    """
  end

  def badge(%{bg: _, text: _} = assigns) do
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
