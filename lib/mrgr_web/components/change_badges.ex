defmodule MrgrWeb.Component.PendingMerge do

  use Phoenix.Component


  def change_badges(assigns) do
    ~H"""
      <%= if has_migration?(assigns.merge) do %>
        <p class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
          <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">migration</p>
        </p>
      <% end %>

    """
  end


  def has_migration?(%{files_changed: files}) do
    Enum.any?(files, fn f ->
      String.starts_with?(f, "priv/repo/migrations")
    end)
  end


end
