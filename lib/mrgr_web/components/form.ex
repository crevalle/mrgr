defmodule MrgrWeb.Components.Form do
  use MrgrWeb, :component

  import Phoenix.HTML.Form
  import MrgrWeb.Components.Core
  alias Phoenix.LiveView.JS

  def error(assigns) do
    ~H"""
    <%= MrgrWeb.ErrorHelpers.error_tag(@form, @attr, class: "mt-1 text-sm text-red-600") %>
    """
  end

  def textarea(assigns) do
    defaults = [
      rows: 4,
      class:
        "shadow-inner border-teal-500 focus:ring-teal-700 focus:border-teal-700 block w-full sm:text-sm rounded-md"
    ]

    assigns =
      assigns
      |> assign(:opts, Keyword.merge(defaults, assigns.opts))

    ~H"""
    <%= textarea(@form, @field, @opts) %>
    """
  end

  def check(assigns) do
    assigns = assign_new(assigns, :detail_text, fn -> nil end)

    ~H"""
    <div class="grid grid-cols-3 gap-4 items-center border-t border-gray-200 pt-5">
      <%= label(@form, @attr, @description,
        class: "block text-sm font-medium text-gray-700 mt-px pt-2"
      ) %>
      <div class="mt-1 mt-0 flex items-center col-span-2">
        <.checkbox f={@form} attr={@attr} />
        <p :if={@detail_text} class="ml-4 text-sm text-gray-500">
          <%= @detail_text %>
        </p>
      </div>
    </div>
    """
  end

  # like hte one below, but sends the click event to myself
  # ie, goes into a form component that handles its own events.
  # TODO: flesh it out
  def repo_toggle_item(assigns) do
    color =
      case assigns.selected do
        true -> "bg-emerald-50"
        false -> ""
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <.l
      phx-click={JS.push("toggle-selected-repository", value: %{id: @repo.id})}
      phx-target={@target}
      class={"flex items-center justify-center py-2 border rounded-md border-teal-500 #{@color}"}
      id={"repo-#{@repo.id}"}
    >
      <div>
        <%= @repo.name %>
      </div>
    </.l>
    """
  end

  def toggle_block(assigns) do
    color =
      case assigns.selected do
        true -> "bg-emerald-50"
        false -> ""
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <.l
      phx-click={JS.push("toggle-selected-repository", value: %{repo_id: @repo.id})}
      class={"flex items-center justify-center py-2 border rounded-md border-teal-500 #{@color}"}
      id={"repo-#{@repo.id}"}
    >
      <div>
        <%= @repo.name %>
      </div>
    </.l>
    """
  end

  def color_input(assigns) do
    value = Phoenix.HTML.Form.input_value(assigns.f, :color)

    value =
      case String.starts_with?(value, "#") do
        true -> value
        false -> "##{value}"
      end

    assigns =
      assigns
      |> assign(:value, value)

    ~H"""
    <%= color_input(@f, :color,
      value: @value,
      class:
        "shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:max-w-xs sm:text-sm border-gray-300 rounded-md"
    ) %>
    """
  end

  def janky_input(%{type: "text"} = assigns) do
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
    <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5">
      <%= label(@f, @field, class: "block text-sm font-medium text-gray-700 sm:mt-px sm:pt-2") %>
      <div class="mt-1 sm:mt-0 sm:col-span-2">
        <%= text_input(@f, @field,
          required: @required,
          autocomplete: @autocomplete,
          value: @value,
          placeholder: @placeholder,
          class:
            [@common_styles] ++
              [if(Keyword.get(@f.errors, @field), do: @error_styles, else: @success_styles)]
        ) %>
        <p :if={@required} class="pt-1 text-gray-500 text-xs italic">required</p>
        <.error form={@f} attr={@field} />
        <p class="mt-2 text-sm text-gray-500"><%= render_slot(@secondary) %></p>
      </div>
    </div>
    """
  end

  attr :type, :any, default: nil
  attr :field, :any, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(min)

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@field.name}
      id={@field.id}
      value={@field.value}
      class={[
        "shadow-inner focus:ring-emerald-500 focus:border-emerald-500 border-gray 300 rounded-md",
        @class
      ]}
      {@rest}
    />
    """
  end

  def notification_email_form(%{changeset: nil} = assigns) do
    ~H"""
    <div class="flex items-center space-x-4">
      <p>
        <%= @current_user.notification_email %>
        <.l phx-click="edit" class="text-xs">change</.l>
      </p>
      <p :if={is_nil(@current_user.notification_email)} class="text-red-800 text-sm">
        * Required for HIF alerts and weekly changelog emails.
      </p>
    </div>
    """
  end

  def notification_email_form(assigns) do
    ~H"""
    <.form :let={f} for={@changeset} phx-submit="save">
      <div class="flex flex-col">
        <div class="flex items-center space-x-1">
          <%= text_input(f, :notification_email,
            placeholder: "you@company_email.com",
            class: "w-full text-sm font-medium rounded-md text-gray-700 mt-px pt-2"
          ) %>
          <.button
            type="submit"
            phx-disable-with="Saving..."
            class="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500"
          >
            Save
          </.button>
        </div>
        <.error form={f} attr={:notification_email} />
      </div>
    </.form>
    """
  end
end
