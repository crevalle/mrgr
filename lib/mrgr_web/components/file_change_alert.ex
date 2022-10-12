defmodule MrgrWeb.Components.FileChangeAlert do
  use MrgrWeb, :component

  def badges(assigns) do
    ~H"""
      <div class="mt-2 flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
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
end
