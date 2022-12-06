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

  def toggle(js \\ %JS{}, opts) do
    JS.toggle(
      to: opts[:to],
      in: toggle_in_transition(),
      out: toggle_out_transition()
    )
  end

  defp toggle_in_transition do
    {"transition ease-out duration-100", "transform opacity-0 scale-95",
     "transform opacity-100 scale-100"}
  end

  defp toggle_out_transition do
    {"transition ease-in duration-75", "transform opacity-100 scale-100",
     "transform opacity-0 scale-95"}
  end
end
