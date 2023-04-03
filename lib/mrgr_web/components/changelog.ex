defmodule MrgrWeb.Components.Changelog do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.PullRequest, only: [line_diff: 1, changed_file: 1]

  def weekly_changelog(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2 p-2" id={@id}>
      <div class="flex items-center justify-between">
        <.h3><%= format_week(@date) %></.h3>
        <div class="flex space-x-4 items-center">
          <.line_diff additions={total_additions(@prs)} deletions={total_deletions(@prs)} />
          <span class="text-sm text-gray-500"><%= Enum.count(@prs) %></span>
        </div>
      </div>
      <.pr_list pull_requests={@prs} />
    </div>
    """
  end

  def total_additions(prs) do
    prs
    |> Enum.map(& &1.additions)
    |> Enum.sum()
  end

  def total_deletions(prs) do
    prs
    |> Enum.map(& &1.deletions)
    |> Enum.sum()
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
    <div id={"pull-request-#{@pr.id}"} class="flex flex-col">
      <div class="flex flex-start space-x-2">
        <span>[<%= @pr.repository.name %>]</span>
        <div class="flex flex-col items-start">
          <div class="flex items-center space-x-2">
            <.l href="#" phx-click={toggle_detail(@pr.id)}>
              <div class="flex items-center space-x-1">
                <span><%= @pr.title %></span>
                <.icon
                  opts={[id: "pr-#{@pr.id}-detail-chevron"]}
                  name="chevron-right"
                  class="h-4 w-4"
                />
              </div>
            </.l>
            <span>@<%= Mrgr.Schema.PullRequest.author_name(@pr) %></span>
            <.line_diff additions={@pr.additions} deletions={@pr.deletions} />
            <.time_to_close opened_at={@pr.opened_at} merged_at={@pr.merged_at} />
          </div>
          <div class="flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
            <.badge :for={hif <- @pr.high_impact_file_rules} item={hif} />
          </div>
        </div>
      </div>

      <.details
        id={@pr.id}
        body={@pr.raw["body"]}
        comments={@pr.comments}
        files_changed={@pr.files_changed}
        hifs={@pr.high_impact_file_rules}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :body, :string, default: nil
  attr :comments, :list, required: true
  attr :files_changed, :list, required: true
  attr :hifs, :list, required: true

  def details(assigns) do
    comments_tab_id = "details-#{assigns.id}-comments"
    files_changed_tab_id = "details-#{assigns.id}-files-changed"
    comments_list_id = "details-#{assigns.id}-comments-list"
    files_changed_list_id = "details-#{assigns.id}-files-changed-list"

    toggler =
      MrgrWeb.JS.toggle_class("selected", to: "##{comments_tab_id}")
      |> MrgrWeb.JS.toggle_class("selected", to: "##{files_changed_tab_id}")
      |> MrgrWeb.JS.toggle(to: "##{comments_list_id}")
      |> MrgrWeb.JS.toggle(to: "##{files_changed_list_id}")

    assigns =
      assigns
      |> assign(:div_id, "pr-#{assigns.id}-details")
      |> assign(:comments_tab_id, comments_tab_id)
      |> assign(:files_changed_tab_id, files_changed_tab_id)
      |> assign(:comments_list_id, comments_list_id)
      |> assign(:files_changed_list_id, files_changed_list_id)
      |> assign(:toggler, toggler)

    ~H"""
    <div id={@div_id} class="flex flex-col space-y-2 p-2 bg-white rounded-md hidden mt-2 mb-6">
      <.body text={@body} />

      <div class="flex items-center">
        <.tab id={@comments_tab_id} selected="selected" toggler={@toggler}>
          Comments <.pr_count_badge items={@comments} />
        </.tab>
        <.tab id={@files_changed_tab_id} toggler={@toggler}>
          Files Changed <.pr_count_badge items={@files_changed} />
        </.tab>
      </div>
      <.comments id={@comments_list_id} comments={@comments} />
      <.filenames id={@files_changed_list_id} files_changed={@files_changed} hifs={@hifs} />
      <div class="flex justify-end">
        <.l href="#" phx-click={toggle_detail(@id)}>
          <span class="text-sm">[close]</span>
        </.l>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :selected, :string, default: nil
  attr :toggler, :string, required: true
  slot :inner_block, required: true

  def tab(assigns) do
    ~H"""
    <div
      class={"flex items-center tab #{@selected}"}
      id={@id}
      phx-click={@toggler}
      aria-selected="false"
      role="presentation"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def body(%{text: text} = assigns) when is_nil(text) or text == "" do
    ~H"""
    <span class="text-gray-500 italic text-sm">No description provided.</span>
    """
  end

  def body(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <h5>Description</h5>
      <div>
        <%= md(@text) %>
      </div>
    </div>
    """
  end

  def comments(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col">
      <div :for={comment <- @comments}>
        <%= md(Mrgr.Schema.Comment.body(comment)) %>
      </div>
    </div>
    """
  end

  def filenames(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col hidden">
      <.changed_file :for={f <- @files_changed} filename={f} hifs={@hifs} />
    </div>
    """
  end

  def time_to_close(assigns) do
    ~H"""
    <span class="text-gray-500 text-sm"><%= format_ttc(@opened_at, @merged_at) %></span>
    """
  end

  def toggle_detail(id) do
    MrgrWeb.JS.toggle(to: "#pr-#{id}-details")
    |> JS.dispatch("icon:rotate-90", to: "#pr-#{id}-detail-chevron")
  end
end
