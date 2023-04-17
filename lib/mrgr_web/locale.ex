defmodule MrgrWeb.Locale do
  import Mrgr.Tuple, only: [cont: 1]
  import Phoenix.LiveView, only: [get_connect_params: 1]
  import Phoenix.LiveView.Utils, only: [assign: 3]

  @default_locale "en"
  @default_timezone "UTC"
  @default_timezone_offset 0

  def on_mount(:default, _params, _session, socket) do
    socket
    |> assign_locale()
    |> assign_timezone()
    |> assign_timezone_offset()
    |> cont()
  end

  defp assign_locale(socket) do
    locale = get_connect_params(socket)["locale"] || @default_locale
    assign(socket, :locale, locale)
  end

  defp assign_timezone(socket) do
    timezone = get_connect_params(socket)["timezone"] || @default_timezone

    socket
    |> assign(:timezone, timezone)
    |> assign(:tz, timezone)
  end

  defp assign_timezone_offset(socket) do
    timezone_offset = get_connect_params(socket)["timezone_offset"] || @default_timezone_offset

    assign(socket, :timezone_offset, timezone_offset)
  end
end
