defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view

  def mount(params, %{"user_id" => user_id} = session, socket) do
    if connected?(socket) do
      subscribe()

      current_user = MrgrWeb.Plug.Auth.find_user(user_id)
      merges = Mrgr.Merge.pending_merges(current_user) |> assign_cardinality()

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

    <div phx-hook="Drag" id="drag">
      <div class="table-header row">
        <div>#</div>
        <div>id</div>
        <div>Status</div>
        <div>Number</div>
        <div>Title</div>
        <div>Branch</div>
        <div>Current SHA</div>
        <div>Updated</div>
        <div>Opened</div>
        <div>Actions</div>
      </div>
      <div class="table-body dropzone" id="pending-merge-list">
        <%= for merge <- assigns.pending_merges do %>
          <div draggable="true" class="draggable row" id={"merge-#{merge.id}"}>
            <div><%= merge.cardinality %></div>
            <div><%= merge.id %></div>
            <div><%= merge.status %></div>
            <div><%= merge.number %></div>
            <div><%= merge.title %></div>
            <div><%= merge.head.ref %></div>
            <div><%= shorten_sha(merge.head.sha) %></div>
            <div><%= ts(merge.updated_at, assigns.timezone) %></div>
            <div><%= ts(merge.opened_at, assigns.timezone) %></div>
            <div><button phx-click="merge" phx-value-id={merge.id}>Merge</button></div>
          </div>
        <% end %>
      </div>
    </div>
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

  defp assign_cardinality(merges) do
    # gives us a random ordering
    merges
    |> Enum.shuffle()
    |> Enum.reduce([], fn m, acc ->
      idx = Enum.count(acc) + 1

      [%{m | cardinality: idx} | acc]
    end)
    |> Enum.reverse()
  end
end
