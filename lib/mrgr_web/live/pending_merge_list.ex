defmodule MrgrWeb.Live.PendingMergeList do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    current_user = MrgrWeb.Plug.Auth.find_user(user_id)
    merges = Mrgr.Merge.pending_merges(current_user)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:pending_merges, merges)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <button phx-click="refresh">Refresh PRs</button>

    <table>
      <th>id</th>
      <th>Status</th>
      <th>Repo</th>
      <th>Number</th>
      <th>Title</th>
      <th>Author</th>
      <th>Branch</th>
      <th>Current SHA</th>
      <th>Updated</th>
      <th>Opened</th>
      <th></th>
      <%= for merge <- assigns.pending_merges do %>
        <tr>
          <td><%= merge.id %></td>
          <td><%= merge.status %></td>
          <td><%= merge.repository.name %></td>
          <td><%= merge.number %></td>
          <td><%= merge.title %></td>
          <td><%= merge.user.login %></td>
          <td><%= merge.head.ref %></td>
          <td><%= shorten_sha(merge.head.sha) %></td>
          <td><%= ts(merge.updated_at) %></td>
          <td><%= ts(merge.opened_at) %></td>
          <td><button phx-click="merge" phx-value-id={merge.id}>Merge</button></td>
        </tr>
      <% end %>
    </table>
    """
  end

  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user
    IO.inspect(user)

    # dangerous!  anyone can do this right now.
    installation = Mrgr.Repo.preload(user.current_installation, :repositories)
    Mrgr.Installation.refresh_merges!(installation)

    merges = Mrgr.Merge.pending_merges(user)

    socket = assign(socket, :pending_merges, merges)

    {:noreply, socket}
  end

  def handle_event("merge", %{"id" => merge_id}, socket) do
    Mrgr.Merge.merge!(merge_id, socket.assigns.current_user)
    |> case do
      {:ok, _merge} ->
        # TODO: remove from list?
        socket
        |> put_flash(:info, "Merged! 🥳")
        |> noreply()

      {:error, message} ->
        socket
        |> put_flash(:error, message)
        |> noreply()
    end
  end
end
