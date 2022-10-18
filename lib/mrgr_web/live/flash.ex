defmodule MrgrWeb.Live.Flash do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def put(socket, key, message) do
    Mrgr.PubSub.broadcast_flash(socket.assigns.current_user, key, message)

    socket
  end

  def mount(_params, _session, socket) do
    Mrgr.PubSub.subscribe_to_flash(socket.assigns.current_user)

    socket
    |> ok
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={live_flash(@flash, :info)} id="flash-info" class="alert alert-info" phx-click="lv:clear-flash" role="alert">
        <%= live_flash(@flash, :info) %>
      </p>

      <p :if={live_flash(@flash, :error)} id="flash-error" class="alert alert-danger" phx-click="lv:clear-flash" role="alert">
        <%= live_flash(@flash, :error) %>
      </p>
    </div>
    """
  end

  def handle_info(%{event: "flash:" <> type, payload: message}, socket) do
    set_clear_flash_timer()

    socket
    |> put_flash(type, message)
    |> noreply()
  end

  def handle_info("clear_flash", socket) do
    socket
    |> put_flash(:info, nil)
    |> put_flash(:error, nil)
    |> noreply()
  end

  defp set_clear_flash_timer do
    Process.send_after(self(), "clear_flash", 3000)
  end
end
