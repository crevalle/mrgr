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
    color = assigns[:color] || "text-gray-900"

    assigns = Phoenix.LiveView.assign(assigns, :color, color)

    ~H"""
    <h3 class={"text-lg leading-6 font-medium #{@color}"}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  def button(assigns) do
    colors =
      if assigns[:disabled] do
        "bg-gray-600 hover:bg-gray-700 focus:ring-gray-500"
      else
        assigns[:colors]
      end

    class =
      "inline-flex items-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white focus:outline-none focus:ring-2 focus:ring-offset-2 #{colors}"

    type = if assigns[:submit], do: "submit", else: false

    extra = assigns_to_attributes(assigns, [:submit])

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
    class = "whitespace-nowrap px-3 py-4 text-gray-700 #{assigns[:class]}"

    assigns = Phoenix.LiveView.assign(assigns, :class, class)

    ~H"""
    <td class={@class}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  def table_attr(assigns) do
    label =
      assigns.key
      |> to_string()
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    value =
      case Map.get(assigns.obj, assigns.key) do
        %DateTime{} = dt ->
          ts(dt, assigns.tz)

        map when is_map(map) ->
          Jason.encode!(map, pretty: true)

        list when is_list(list) ->
          Enum.join(list, ", ")

        simple ->
          simple
      end

    assigns =
      assigns
      |> Phoenix.LiveView.assign(:label, label)
      |> Phoenix.LiveView.assign(:value, value)

    ~H"""
    <.tr striped={true}>
      <.td class="font-bold"><%= @label %></.td>
      <.td><%= @value %></.td>
    </.tr>

    """
  end

  def installation_table(assigns) do
    ~H"""
      <table class="min-w-full">
        <.table_attr obj={@installation} key={:access_tokens_url} ./>
        <.table_attr obj={@installation} key={:app_id} ./>
        <.table_attr obj={@installation} key={:app_slug} ./>
        <.table_attr obj={@installation} key={:events} ./>
        <.table_attr obj={@installation} key={:external_id} ./>
        <.table_attr obj={@installation} key={:html_url} ./>
        <.table_attr obj={@installation} key={:installation_created_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:permissions} ./>
        <.table_attr obj={@installation} key={:repositories_url} ./>
        <.table_attr obj={@installation} key={:repository_selection} ./>
        <.table_attr obj={@installation} key={:target_id} ./>
        <.table_attr obj={@installation} key={:target_type} ./>
        <.table_attr obj={@installation} key={:token} tz={@tz} ./>
        <.table_attr obj={@installation} key={:token_expires_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:updated_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:inserted_at} tz={@tz} ./>
      </table>
    """
  end
end
