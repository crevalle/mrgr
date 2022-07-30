defmodule MrgrWeb.Components.UI do
  use MrgrWeb, :component

  def h1(assigns) do
    ~H"""
    <h1 class="text-xl font-semibold text-gray-900">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  def h3(assigns) do
    ~H"""
    <h3 class="text-lg leading-6 font-medium text-gray-900">
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  def button(assigns) do
    color = assigns[:color] || "emerald"

    class =
      "ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-#{color}-600 hover:bg-#{color}-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-#{color}-500"

    type = if assigns[:submit], do: "submit", else: false

    assigns =
      assigns
      |> Phoenix.LiveView.assign(:type, type)
      |> Phoenix.LiveView.assign(:class, class)

    ~H"""
      <button type={@type} class={@class} >
        <%= render_slot(@inner_block) %>
      </button>

    """
  end
end
