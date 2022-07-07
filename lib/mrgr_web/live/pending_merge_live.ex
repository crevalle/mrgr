defmodule MrgrWeb.PendingMergeLive do
  use MrgrWeb, :live_view

  def mount(params, %{"user_id" => user_id}, socket) do
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

    <div phx-hook="Drag" id="drag">
      <div class="table-header row">
        <div>#</div>
        <div>ID</div>
        <div>Labels</div>
        <div>Title</div>
        <div>Branch</div>
        <div>Current SHA</div>
        <div>Updated</div>
        <div>Opened</div>
        <div>Actions</div>
      </div>
      <div class="table-body dropzone" id="pending-merge-list">
        <%= for merge <- assigns.pending_merges do %>
          <div draggable="true" class="draggable column" id={"merge-#{merge.id}"}>
            <div class="row">
              <div><%= merge.merge_queue_index %></div>
              <div><%= merge.id %></div>
              <div>
                <%= if has_migration?(merge) do %>
                  <span class="label-inline">migration</span>
                <% end %>
              </div>
              <div>
                <%= link merge.title, to: Routes.pending_merge_path(@socket, :show, merge.id) %>
                <%= link to: external_merge_url(merge), target: "_blank" do %>
                  <i class="fa fa-arrow-up-right-from-square"></i>
                <% end %>
              </div>
              <div><%= merge.head.ref %></div>
              <div><%= shorten_sha(merge.head.sha) %></div>
              <div><%= ts(merge.updated_at, assigns.timezone) %></div>
              <div><%= ts(merge.opened_at, assigns.timezone) %></div>
              <div><button phx-click="add-merge-message" phx-value-id={merge.id}>Merge</button></div>
            </div>
            <div>
              <.form let={f} for={:merge}, phx-submit="merge">
                <%= textarea f, :message, placeholder: "Commit message defaults to PR title.  Enter additional info here." %>
                <%= hidden_input f, :id, value: merge.id %>
                <%= submit "Save", phx_disable_with: "Merging..." %>
              </.form>
            </div>

          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("dropped", %{"draggedId" => id, "draggableIndex" => index}, socket) do
    dragged = find_dragged(socket.assigns.pending_merges, get_id(id))

    merges =
      socket.assigns.pending_merges
      |> update_merge_order(dragged, index)

    socket
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user

    # dangerous!  anyone can do this right now.
    installation = Mrgr.Repo.preload(user.current_installation, :repositories)
    Mrgr.Installation.refresh_merges!(installation)

    merges = Mrgr.Merge.pending_merges(user)

    socket = assign(socket, :pending_merges, merges)

    {:noreply, socket}
  end

  def handle_event("merge", %{"merge" => params}, socket) do
    id = String.to_integer(params["id"])
    message = params["message"]

    Mrgr.Merge.merge!(id, message, socket.assigns.current_user)
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

  # pulls the id off the div constructed above
  defp get_id("merge-" <> id), do: String.to_integer(id)

  defp find_dragged(merges, id) do
    Mrgr.MergeQueue.find_merge_by_id(merges, id)
  end

  defp update_merge_order(merges, updated_item, new_index) do
    Mrgr.MergeQueue.update(merges, updated_item, new_index)
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

  def handle_info(%{event: "synchronized", payload: merge}, socket) do
    hydrated = Mrgr.Merge.preload_for_pending_list(merge)
    merges = replace_updated(socket.assigns.pending_merges, hydrated)

    socket
    |> put_flash(
      :info,
      "Open PR \"#{merge.title}\" updated.  New head is #{shorten_sha(merge.head.sha)}."
    )
    |> assign(:pending_merges, merges)
    |> noreply()
  end

  defp put_closed_flash_message(socket, %{merged_at: nil} = merge) do
    put_flash(socket, :warn, "#{merge.title} closed, but not merged")
  end

  defp put_closed_flash_message(socket, merge) do
    put_flash(socket, :info, "#{merge.title} merged! 🍾")
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

  def has_migration?(%{files_changed: files}) do
    Enum.any?(files, fn f ->
      String.starts_with?(f, "priv/repo/migrations")
    end)
  end

  def external_merge_url(merge) do
    Mrgr.Schema.Merge.external_merge_url(merge)
  end
end
