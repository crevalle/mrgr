defmodule MrgrWeb.Components.Live.ChangelogComponent do
  use MrgrWeb, :live_component

  import MrgrWeb.Components.Changelog

  def render(assigns) do
    ~H"""
    <div id="changelog-list-body" class="flex flex-col space-y-6 divide-y" phx-update="stream">
      <div
        :for={{dom_id, {date, prs}} <- @pull_requests}
        class="flex flex-col space-y-2 p-2"
        id={dom_id}
      >
        <div class="flex items-center justify-between">
          <.h3><%= format_week(date) %></.h3>
          <span class="text-sm text-gray-500 italic"><%= Enum.count(prs) %></span>
        </div>
        <.pr_list pull_requests={prs} />
      </div>
    </div>
    """
  end
end
