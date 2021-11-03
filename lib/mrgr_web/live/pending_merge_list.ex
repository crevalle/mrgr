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
    <table>
      <th>id</th>
      <th>Repo</th>
      <th>Number</th>
      <th>Title</th>
      <th>Author</th>
      <th>Current SHA</th>
      <th>Updated</th>
      <th>Opened</th>
      <th></th>
      <%= for merge <- assigns.pending_merges do %>
        <tr>
          <td><%= merge.id %></td>
          <td><%= merge.repository.name %></td>
          <td><%= merge.number %></td>
          <td><%= merge.title %></td>
          <td><%= merge.user.login %></td>
          <td><%= shorten_sha(merge.head.sha) %></td>
          <td><%= ts(merge.updated_at) %></td>
          <td><%= ts(merge.opened_at) %></td>
          <td><button phx-click="merge" phx-value-id={merge.id}>Merge</button></td>
        </tr>
      <% end %>
    </table>
    """
  end

  def handle_event("merge", %{"id" => merge_id}, socket) do
    IO.inspect(merge_id, label: "MERGE")
    # TODO: merge that shit.
    {:noreply, socket}
  end
end
