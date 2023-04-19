defmodule MrgrWeb.Components.Live.UserRepoHIFList do
  use MrgrWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.table>
        <th class="p-3 bg-gray-100 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
          High Impact File Alert
        </th>
        <th class="p-3 bg-gray-100 text-left text-xs font-medium uppercase tracking-wide text-gray-500">
          Badge
        </th>
        <th class="p-3 bg-gray-100 text-xs font-medium tracking-wide text-gray-500 flex items-center justify-center">
          <span class="uppercase">Channels</span>
        </th>
        <%= for {repo, hifs} <- @hifs_by_repo do %>
          <tr class="border-t border-gray-300 bg-stone-50 font-semibold" id={"repo-#{repo.id}"}>
            <.td class="rounded-lg py-2 flex items-center">
              <span class="pr-2"><%= repo.name %></span>
              <.language_icon language={repo.language} />
            </.td>
            <.td></.td>
            <.td></.td>
          </tr>
          <.live_component
            :for={hif <- hifs}
            module={MrgrWeb.Components.Live.UserHIF}
            id={"hif-#{hif.id}"}
            hif={hif}
            slack_unconnected={@slack_unconnected}
          />
        <% end %>
      </.table>
    </div>
    """
  end
end
