defmodule MrgrWeb.Live.InstallationLoading do
  use MrgrWeb, :live_view

  on_mount MrgrWeb.Plug.Auth

  def mount(_session, _params, socket) do
    set_dot_clock()

    Process.send_after(self(), "sync_complete", 1000)

    socket
    |> assign(:dots, cycle_dots())
    |> ok()
  end

  def render(assigns) do
    ~H"""

    <div class="flex flex-col mt-8 space-y-4">
      <p>We've connected Mrgr to your <span class="font-bold"><%= @current_user.current_installation.account.login %></span> account.</p>

      <p>We are currently syncing all of your data.  When that's done, you'll be automatically redirected to get started. 🙂
    </p>

    <div class="flex space-x-4">
      <p><%= @dots %></p>
    </div>


    </div>

    """
  end

  def set_dot_clock do
    Process.send_after(self(), "cycle_dots", 100)
  end

  def handle_info("sync_complete", socket) do
    socket
    |> assign(:dots, "OK!")
    |> redirect(to: Routes.pending_merge_path(MrgrWeb.Endpoint, :index))
    |> noreply()
  end

  def handle_info("cycle_dots", socket) do
    dots = cycle_dots(socket.assigns.dots)

    set_dot_clock()

    socket
    |> assign(:dots, dots)
    |> noreply()
  end

  def cycle_dots(), do: "Loading "
  def cycle_dots("Loading "), do: "Loading ."
  def cycle_dots("Loading ."), do: "Loading .."
  def cycle_dots("Loading .."), do: "Loading ..."
  def cycle_dots("Loading ..."), do: "Loading ...."
  def cycle_dots("Loading ...."), do: "Loading "
end
