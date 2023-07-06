defmodule MrgrWeb.JS do
  alias Phoenix.LiveView.JS

  def show_detail do
    show_detail(%JS{})
  end

  def show_detail(%Phoenix.LiveView.Socket{} = socket) do
    Phoenix.LiveView.push_event(socket, "show-element", %{id: "detail-pane"})
  end

  def show_detail(%JS{} = js) do
    js
    |> JS.add_class("show", to: "#detail-pane")
  end

  def hide_detail(input \\ %JS{})

  def hide_detail(%Phoenix.LiveView.Socket{} = socket) do
    Phoenix.LiveView.push_event(socket, "hide-element", %{id: "detail-pane"})
  end

  def hide_detail(js) do
    js
    |> JS.remove_class("show", to: "#detail-pane")
  end

  # def hide_modal(js \\ %JS{}, id) do
  # JS.hide(js,
  # to: "##{id}",
  # transition: toggle_out_transition()
  # )
  # end

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
    JS.toggle(js,
      to: opts[:to],
      in: toggle_in_transition(),
      out: toggle_out_transition(),
      display: opts[:display] || "block"
    )
  end

  @spec toggle_class(js :: map(), classes :: String.t(), opts :: keyword()) :: map()
  def toggle_class(js \\ %JS{}, classes, opts) when is_binary(classes) do
    if not Keyword.has_key?(opts, :to) do
      raise ArgumentError, "Missing option `:to`"
    end

    case String.split(classes) do
      [class] ->
        opts_remove_class = Keyword.update!(opts, :to, fn selector -> "#{selector}.#{class}" end)

        opts_add_class =
          Keyword.update!(opts, :to, fn selector -> "#{selector}:not(.#{class})" end)

        js
        |> JS.remove_class(class, opts_remove_class)
        |> JS.add_class(class, opts_add_class)

      classes ->
        Enum.reduce(classes, js, fn class, js ->
          toggle_class(js, class, opts)
        end)
    end
  end

  def toggle_in_transition do
    {"transition ease-out duration-100", "transform opacity-0 scale-95",
     "transform opacity-100 scale-100"}
  end

  def toggle_out_transition do
    {"transition ease-in duration-75", "transform opacity-100 scale-100",
     "transform opacity-0 scale-95"}
  end
end
