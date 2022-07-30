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

    extra = assigns_to_attributes(assigns, [:submit, :color])

    assigns =
      assigns
      |> Phoenix.LiveView.assign(:type, type)
      |> Phoenix.LiveView.assign(:class, class)
      |> Phoenix.LiveView.assign(:extra, extra)

    ~H"""
      <button type={@type} class={@class} {@extra} >
        <%= render_slot(@inner_block) %>
      </button>
    """
  end

  def heading(assigns) do
    assigns = assign_new(assigns, :description, fn -> nil end)

    ~H"""
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <.h1><%= @title %></.h1>
        <%= if @description do %>
          <p class="mt-2 text-sm text-gray-700"><%= @description %></p>
        <% end %>
      </div>
    </div>
    """
  end

  def th(assigns) do
    uppercase = if assigns[:uppercase], do: "uppercase", else: nil

    class = "px-3 py-3.5 text-left text-sm font-semibold text-gray-900 #{uppercase}"

    # <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Pattern</th>
    assigns = Phoenix.LiveView.assign(assigns, :class, class)

    ~H"""
    <th scope="col" class={@class}>
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  def tr(assigns) do
    striped = if assigns[:striped], do: "even:bg-white odd:bg-gray-50", else: nil

    class = "border-t border-gray-300 py-4 #{striped}"

    assigns = Phoenix.LiveView.assign(assigns, :class, class)

    ~H"""
    <tr class={@class}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  def td(assigns) do
    # striped = if assigns[:striped], do: "even:bg-white odd:bg-gray-50", else: nil

    class = "whitespace-nowrap px-3 py-4 text-gray-700"

    assigns = Phoenix.LiveView.assign(assigns, :class, class)

    ~H"""
    <td class={@class}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end
end
