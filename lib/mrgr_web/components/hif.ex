defmodule MrgrWeb.Components.HIF do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  def hif_for_repo(assigns) do
    ~H"""
    <.rounded_box id={"repo-#{@repo.id}"}>
      <.repo_header_row repo={@repo} />

      <table :if={Enum.any?(@repo.high_impact_file_rules)} class="min-w-full table-fixed">
        <thead>
          <tr class="border-t border-gray-200">
            <th class="hif-column-header pl-6 text-left w-96">
              File Pattern
            </th>
            <th class="hif-column-header text-left w-72">Badge</th>
            <th class="hif-column-header text-center w-64">
              Channels
            </th>
            <th class="hif-column-header"></th>
          </tr>
        </thead>

        <tbody class="bg-white">
          <tr :for={hif <- @repo.high_impact_file_rules} class="border-t border-gray-300">
            <td class="whitespace-nowrap pl-6 py-2">
              <.hif_pattern pattern={hif.pattern} />
            </td>
            <td class="whitespace-nowrap py-2 text-sm text-gray-500">
              <.badge item={hif} />
            </td>
            <td>
              <.live_component
                module={MrgrWeb.Components.Live.NotificationChannelToggle}
                id={"hif-#{hif.id}"}
                obj={hif}
                slack_unconnected={@slack_unconnected}
              />
            </td>
            <td class="whitespace-nowrap pr-4 py-2 text-right text-sm">
              <.l phx-click={
                JS.push("edit-hif", value: %{repo: @repo.id, hif: hif.id})
                |> show_detail()
              }>
                Edit
              </.l>
            </td>
          </tr>
        </tbody>
      </table>
    </.rounded_box>
    """
  end

  def repo_header_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between bg-gray-100 py-3.5 pl-6 pr-4 text-left text-sm font-semibold text-gray-900">
      <div class="flex">
        <span class="pr-2"><%= @repo.name %></span>
        <.language_icon language={@repo.language} />
      </div>
      <.l phx-click={
        JS.push("add-hif", value: %{id: @repo.id})
        |> show_detail()
      }>
        <div class="flex items-center">
          <.icon name="plus-circle" class="mr-1 flex-shrink-0 h-6 w-6" />
        </div>
      </.l>
    </div>
    """
  end
end
