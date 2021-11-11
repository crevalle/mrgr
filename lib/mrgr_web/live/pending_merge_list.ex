defmodule MrgrWeb.Live.PendingMergeList do
  use MrgrWeb, :live_view

  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket) do
      subscribe()

      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      merges = Mrgr.Merge.pending_merges(current_user)


      socket
      |> assign(:current_user, current_user)
      |> assign(:pending_merges, merges)
      |> ok()
    else
      socket
      |> assign(:current_user, nil)
      |> assign(:pending_merges, [])
      |> ok()
    end
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
        socket
        |> put_flash(:info, "OK! 🥳")
        |> noreply()

      {:error, message} ->
        socket
        |> put_flash(:error, message)
        |> noreply()
    end
  end

  # event bus
  def subscribe do
    Mrgr.PubSub.subscribe(Mrgr.Merge.topic())
  end

  # repoened will put it at the top, which may not be what we want
  def handle_info(%{event: event, payload: payload}, socket)
      when event in ["created", "reopened"] do
    merges = socket.assigns.pending_merges

    socket
    |> assign(:pending_merges, [payload | merges])
    |> noreply()
  end

  def handle_info(%{event: "closed", payload: payload}, socket) do
    merges = Enum.reject(socket.assigns.pending_merges, &(&1.id == payload.id))

    socket
    |> put_closed_flash_message(payload)
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = merge) do
    put_flash(socket, :warn, "#{merge.title} closed, but not merged")
  end

  defp put_closed_flash_message(socket, merge) do
    put_flash(socket, :info, "#{merge.title} merged! 🍾")
  end

  def handle_info(%{event: "synchronized", payload: merge}, socket) do
    hydrated = Mrgr.Merge.preload_for_pending_list(merge)
    merges = replace_updated(socket.assigns.pending_merges, hydrated)

    socket
    |> put_flash(:info, "#{merge.title} updated")
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  def replace_updated(merges, updated) do
    updated_id = updated.id

    Enum.map(merges, fn merge ->
      case merge do
        %{id: ^updated_id} ->
          updated

        not_updated ->
          not_updated
      end
    end)
  end
end
