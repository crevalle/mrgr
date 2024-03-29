defmodule MrgrWeb.Components.Live.ToggleRepositoryShowPRs do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={%{}}
        phx-change={JS.push("toggle_show_prs", value: %{id: @repo.id})}
        phx-target={@myself}
      >
        <%= checkbox(f, :show_prs,
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

  def handle_event("toggle_show_prs", %{"show_prs" => "true"}, socket) do
    Mrgr.Repository.make_repo_visible_to_user(socket.assigns.repo, socket.assigns.current_user)

    socket
    |> Flash.put(:info, "Updated!")
    |> assign(:checked, true)
    |> noreply()
  end

  def handle_event("toggle_show_prs", %{"show_prs" => "false"}, socket) do
    Mrgr.Repository.hide_repo_from_user(socket.assigns.repo, socket.assigns.current_user)

    socket
    |> Flash.put(:info, "Updated!")
    |> assign(:checked, false)
    |> noreply()
  end
end
