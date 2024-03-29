defmodule MrgrWeb.Live.Flash do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  def put(socket, key, message) do
    # assumes you've got a current user, bub
    Mrgr.PubSub.broadcast_flash(socket.assigns.current_user, key, message)

    socket
  end

  def mount(_params, %{"user_id" => id}, socket) do
    Mrgr.PubSub.subscribe_to_flash(id)

    if connected?(socket) do
      set_clear_flash_timer()
    end

    socket
    |> assign(:user_id, id)
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <p
      :if={live_flash(@flash, :info)}
      id="flash-info"
      class="alert alert-info"
      phx-click="lv:clear-flash"
      role="alert"
    >
      <%= Phoenix.Flash.get(@flash, :info) %>
    </p>

    <p
      :if={live_flash(@flash, :error)}
      id="flash-error"
      class="alert alert-danger"
      phx-click="lv:clear-flash"
      role="alert"
    >
      <%= Phoenix.Flash.get(@flash, :error) %>
    </p>
    """
  end

  def handle_info(%{event: "flash:" <> type, payload: message}, socket) do
    set_clear_flash_timer()

    socket
    |> put_flash(type, message)
    |> noreply()
  end

  def handle_info(:clear, socket) do
    socket
    |> put_flash(:info, nil)
    |> put_flash(:error, nil)
    |> noreply()
  end

  defp set_clear_flash_timer do
    Process.send_after(self(), :clear, 3000)
  end
end
