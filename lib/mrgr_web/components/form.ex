defmodule MrgrWeb.Components.Form do
  use MrgrWeb, :component

  import Phoenix.HTML.Form

  def error(assigns) do
    ~H"""
      <%= MrgrWeb.ErrorHelpers.error_tag(@form, @attr, class: "mt-2 text-sm text-red-600") %>
    """
  end

  def textarea(assigns) do
    defaults = [
      rows: 4,
      class:
        "shadow-inner border-emerald-100 focus:ring-emerald-500 focus:border-emerald-500 block w-full sm:text-sm border-gray-300 rounded-md"
    ]

    assigns =
      assigns
      |> assign(:opts, Keyword.merge(defaults, assigns.opts))

    ~H"""
      <%= textarea @form, @field, @opts %>
    """
  end

  def check(assigns) do
    ~H"""
      <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-center sm:border-t sm:border-gray-200 sm:pt-5">
        <%= label(@form, @attr, @description, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
        <div class="mt-1 sm:mt-0 flex items-center sm:col-span-2">
          <%= checkbox @form, @attr, class: "shadow-inner focus:ring-emerald-500 focus:border-emerald-500 border-gray-300 rounded-md" %>
          <p class="ml-1 text-sm text-gray-500">
            <%= render_slot(@inner_block) %>
          </p>
        </div>
      </div>
    """
  end

  def toggle_block(assigns) do
    bg_color =
      case assigns.selected do
        true -> "bg-emerald-50"
        false -> ""
      end

    assigns =
      assigns
      |> assign(:bg_color, bg_color)

    ~H"""
    <%= link to: "#", phx_click: "toggle-selected-repository", phx_value_repo_id: @repo.id, class: "flex items-center justify-center py-2 border rounded-md border-teal-500 #{@bg_color}", id: "repo-#{@repo.id}" do %>
      <div>
        <%= @repo.name %>
      </div>
    <% end %>
    """
  end

  def input(%{type: "text"} = assigns) do
    # defaults
    assigns =
      assigns
      |> assign_new(:required, fn -> false end)
      |> assign_new(:autocomplete, fn -> false end)
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(assigns.f, assigns.field) end)
      |> assign_new(:secondary, fn -> [] end)
      |> assign_new(:common_styles, fn ->
        "max-w-lg block w-full sm:max-w-xs sm:text-sm shadow-inner rounded-md"
      end)
      |> assign_new(:error_styles, fn ->
        "pr-10 border-red-300 text-red-900 placeholder-red-300 focus:outline-none focus:ring-red-500 focus:border-red-500"
      end)
      |> assign_new(:success_styles, fn ->
        "focus:ring-emerald-500 focus:border-emerald-500 shadow-sm border-gray-300"
      end)

    ~H"""

    <%= label @f, @field, class: ["block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2"] %>
    <div class="my-1 sm:mt-0 sm:col-span-2 relative rounded-md">
      <div class="flex items-center">
        <%= text_input @f, @field, required: @required, autocomplete: @autocomplete, value: @value, placeholder: @placeholder, class: [@common_styles] ++ [(if Keyword.get(@f.errors, @field), do: @error_styles, else: @success_styles)] %>
        <%= render_slot(@secondary) %>
      </div>
      <.error form={@f} attr={@field} />
    </div>
    """
  end
end
