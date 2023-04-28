defmodule MrgrWeb.Components.Live.ToggleRepositoryMergeFreeze do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={%{}}
        phx-change={JS.push("toggle-merge-freeze")}
        phx-target={@myself}
        data-confirm="Sure about that?"
      >
        <%= checkbox(f, :merge_freeze_enabled,
          class: [
            "shadow-inner focus:ring-emerald-500 focus:border-emerald-500 border-gray-300 rounded-md"
          ],
          value: @checked
        ) %>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> ok()
  end

  def handle_event("toggle-merge-freeze", %{"merge_freeze_enabled" => new_value}, socket) do
    repo = Mrgr.Repository.update_merge_freeze_status(socket.assigns.repo, new_value)

    socket
    |> noreply()
  end
end
