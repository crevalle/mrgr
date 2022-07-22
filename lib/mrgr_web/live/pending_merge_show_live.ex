defmodule MrgrWeb.PendingMergeShowLive do
  use MrgrWeb, :live_view

  def mount(_params, %{"merge_id" => id}, socket) do
    if connected?(socket) do
      merge = Mrgr.Repo.get(Mrgr.Schema.Merge, id)

      socket
      |> assign(:merge, merge)
      |> ok()
    else
      socket
      |> assign(:merge, nil)
      |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Merge <%= @merge.id %></h1>
    <table>
      <th>Number</th>
      <th>Title</th>
      <th>Merge Queue Index</th>
      <th>Files Changed</th>

      <tr>
        <td><%= @merge.number %></td>
        <td><%= @merge.title %></td>
        <td><%= @merge.merge_queue_index %></td>
        <td><pre><%= Enum.join(@merge.files_changed, ", ") %></pre></td>
        <td><%= ts(@merge.inserted_at, assigns.timezone) %></td>
      </tr>
    </table>

    <h3>Raw Data</h3>
    <pre>
      <%= Jason.encode!(@merge.raw, pretty: true) %>
    </pre>

    """
  end
end
