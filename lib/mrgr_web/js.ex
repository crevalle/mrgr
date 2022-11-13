defmodule MrgrWeb.JS do
  alias Phoenix.LiveView.JS

  def show_detail(js \\ %JS{}) do
    js
    |> JS.add_class("show", to: "#detail-pane")
  end

  def hide_detail(input \\ %JS{})

  def hide_detail(%Phoenix.LiveView.Socket{} = socket) do
    Phoenix.LiveView.push_event(socket, "remove-element", %{id: "detail-pane"})
  end

  def hide_detail(js) do
    js
    |> JS.remove_class("show", to: "#detail-pane")
  end

  def show_spinner(js \\ %JS{}, id) do
    JS.show(js,
      to: "##{id}",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
  end

  def hide_spinner(js \\ %JS{}, id) do
    JS.hide(js, to: "##{id}")
  end
end
