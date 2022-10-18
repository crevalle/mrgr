defmodule MrgrWeb.Live.Flash do
  use MrgrWeb, :live_view
  use Mrgr.PubSub.Event

  on_mount MrgrWeb.Plug.Auth

  def mount(_params, _session, socket) do
    Mrgr.PubSub.subscribe_to_flash(socket.assigns.current_user)

    socket
    |> ok
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={live_flash(@flash, :info)} id="flash-info" class="alert alert-info" phx-click={socks("flash-info")} data-do-hide={hide_me("flash-info")} role="alert">
        <%= live_flash(@flash, :info) %>
      </p>

      <p :if={live_flash(@flash, :error)} id="flash-error" class="alert alert-danger" phx-click="lv:clear-flash" role="alert">
        <%= live_flash(@flash, :error) %>
      </p>
    </div>
    """
  end

  def hide_me(js \\ %JS{}, id) do
    JS.hide(js,
      to: "##{id}",
      transition: {"ease-in duration-300", "opacity-100", "opacity-0"}
      # in: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"},
      # out: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
    )
  end

  def handle_info(%{event: "flash:" <> type, payload: message}, socket) do
    set_clear_flash_timer()

    socket
    |> put_flash(type, message)
    |> noreply()
  end

  def socks(id) do

    hide_me(id)
  end

  def handle_info("clear_flash", socket) do


    # push_event(socket, "js-exec", %{
  # to: "#my_spinner",
  # attr: "data-ok-done"
# })


    socket
    |> put_flash(:info, nil)
    |> put_flash(:error, nil)
    |> push_event("js-exec", %{to: "#flash-info", attr: "data-do-hide"})
    |> noreply()
  end

  defp set_clear_flash_timer do
    Process.send_after(self(), "clear_flash", 3000)
  end
end
