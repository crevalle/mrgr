defmodule MrgrWeb.Components.Form do
  use MrgrWeb, :component

  import Phoenix.HTML.Form

  def error(assigns) do
    ~H"""
      <%= MrgrWeb.ErrorHelpers.error_tag(@form, @attr, class: "mt-2 text-sm text-red-600") %>
    """
  end
end
