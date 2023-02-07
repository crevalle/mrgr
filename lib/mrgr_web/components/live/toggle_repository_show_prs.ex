defmodule MrgrWeb.Components.Live.ToggleRepositoryShowPRs do
  use MrgrWeb, :live_component

  import MrgrWeb.Components.Repository

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@cs}
        phx-change={JS.push("toggle_show_prs", value: %{id: @repo.id})}
        phx-target={@myself}
      >
        <.checkbox f={f} , attr={:show_prs} />
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(:cs, changeset(assigns.repo))
    |> ok()
  end

  def changeset(repo, params \\ %{}) do
    Mrgr.Schema.Repository.show_prs_changeset(repo, params)
  end

  def handle_event("toggle_show_prs", %{"repository" => params}, socket) do
    Mrgr.Repository.update_show_prs(socket.assigns.repo, params)

    socket
    |> noreply()
  end
end
