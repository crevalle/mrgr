defmodule MrgrWeb.Components.Changelog do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  def weekly_changelog(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2 p-2" id={@id}>
      <div class="flex items-center justify-between">
        <.h3><%= format_week(@date) %></.h3>
        <span class="text-sm text-gray-500 italic"><%= Enum.count(@prs) %></span>
      </div>
      <.pr_list pull_requests={@prs} />
    </div>
    """
  end

  def pr_list(%{pull_requests: []} = assigns) do
    ~H"""
    <span class="text-gray-500 text-sm"><em>none!</em></span>
    """
  end

  def pr_list(assigns) do
    ~H"""
    <div class="flex flex-col">
      <.pr :for={pr <- @pull_requests} pr={pr} />
    </div>
    """
  end

  def pr(assigns) do
    ~H"""
    <div id={"pull-request-#{@pr.id}"}>
      <div class="flex flex-start space-x-2">
        <span>[<%= @pr.repository.name %>]</span>
        <div class="flex flex-col items-start">
          <div class="flex items-center space-x-2">
            <.l href={Mrgr.Schema.PullRequest.external_pull_request_url(@pr)}>
              <%= @pr.title %>
            </.l>
            <span>(<%= Mrgr.Schema.PullRequest.author_name(@pr) %>)</span>
          </div>
          <div class="flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
            <.badge :for={hif <- @pr.high_impact_file_rules} item={hif} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
