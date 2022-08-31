defmodule MrgrWeb.Components.Form do
  use MrgrWeb, :component

  import Phoenix.HTML.Form

  def error(assigns) do
    ~H"""
      <%= MrgrWeb.ErrorHelpers.error_tag(@form, @attr, class: "mt-2 text-sm text-red-600") %>
    """
  end

  def my_textarea(assigns) do
    defaults = [
      rows: 4,
      class:
        "shadow-sm border-emerald-100 focus:ring-emerald-500 focus:border-emerald-500 block w-full sm:text-sm border-gray-300 rounded-md"
    ]

    opts = Keyword.merge(defaults, assigns.opts)

    ~H"""
      <%= textarea @form, @field, opts %>
    """
  end
end
