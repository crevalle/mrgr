defmodule MrgrWeb.Components.PullRequestFilter do
  use MrgrWeb, :component

  import MrgrWeb.Components.Core
  import MrgrWeb.Components.UI

  def filters(assigns) do
    ~H"""
    <div class="flex flex-col mt-2 space-y-3">
      <div class="flex flex-col space-y-1">
        <div class="aside">
          <p>Create a custom view of your open PRs based on Author, Label, or Repository.</p>
          <p class="flex space-x-1">
            <.l href={~p"/alerts#custom-alerts"} class="flex items-center space-x-1">
              <.icon name="bell" class="h-5 w-5" /> <span>Configure alerts</span>
            </.l>
            <span>to receive notifications when a PR is opened on this dashboard.</span>
          </p>
        </div>
      </div>

      <p class="font-semibold">Available Filters</p>

      <div class="flex items-start space-x-8">
        <.repositories tab={@tab} repos={@repos} />
        <.labels tab={@tab} labels={@labels} />
        <.authors tab={@tab} items={@members} />
        <.draft tab={@tab} draft_statuses={@draft_statuses} />
        <.reviewers tab={@tab} items={@members} />
      </div>
    </div>
    """
  end

  def authors(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-author-dropdown">
            <div class="flex items-center">
              <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />
              <p class="text-gray-500">Authors</p>

              <.dropdown_clicky />
            </div>
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-author-dropdown">
            <:description>
              Filter By Author
            </:description>

            <.dropdown_toggle_list name="author" items={@items}>
              <:row :let={author}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.author_present?(@tab, author) do %>
                      <.icon name="check" class="text-teal-700 h-5 w-5" />
                    <% end %>
                  </div>
                  <div class="flex">
                    <%= img_tag(author.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
                    <%= author.login %>
                  </div>
                </div>
              </:row>
            </.dropdown_toggle_list>
          </.dropdown_menu>
        </div>
      </div>

      <.active_filter_items items={@tab.authors} />
    </div>
    """
  end

  def reviewers(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-reviewer-dropdown">
            <div class="flex items-center">
              <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />
              <p class="text-gray-500">Reviewers</p>

              <.dropdown_clicky />
            </div>
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-reviewer-dropdown">
            <:description>
              Filter By Reviewer
            </:description>

            <.dropdown_toggle_list name="reviewer" items={@items}>
              <:row :let={reviewer}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.reviewer_present?(@tab, reviewer) do %>
                      <.icon name="check" class="text-teal-700 h-5 w-5" />
                    <% end %>
                  </div>
                  <div class="flex">
                    <%= img_tag(reviewer.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
                    <%= reviewer.login %>
                  </div>
                </div>
              </:row>
            </.dropdown_toggle_list>
          </.dropdown_menu>
        </div>
      </div>

      <.active_filter_items items={@tab.reviewers} />
    </div>
    """
  end

  def repositories(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-repository-dropdown">
            <div class="flex items-center">
              <.repository_icon />
              <p class="text-gray-500">Repositories</p>

              <.dropdown_clicky />
            </div>
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-repository-dropdown">
            <:description>
              Filter By Repository
            </:description>

            <.dropdown_toggle_list name="repository" items={@repos}>
              <:row :let={repo}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.repository_present?(@tab, repo) do %>
                      <.icon name="check" class="text-teal-700 h-5 w-5" />
                    <% end %>
                  </div>
                  <%= repo.name %>
                </div>
              </:row>
            </.dropdown_toggle_list>
          </.dropdown_menu>
        </div>
      </div>

      <.active_filter_items items={@tab.repositories} />
    </div>
    """
  end

  def labels(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-label-dropdown">
            <div class="flex items-center">
              <.icon name="tag" class="text-gray-400 mr-1 h-5 w-5" />
              <p class="text-gray-500">Labels</p>

              <.dropdown_clicky />
            </div>
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-label-dropdown">
            <:description>
              Filter By Label
            </:description>

            <.dropdown_toggle_list name="label" items={@labels}>
              <:row :let={label}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.label_present?(@tab, label) do %>
                      <.icon name="check" class="text-teal-700 h-5 w-5" />
                    <% end %>
                  </div>
                  <.badge item={label} />
                </div>
              </:row>
            </.dropdown_toggle_list>
          </.dropdown_menu>
        </div>
      </div>

      <.active_filter_items items={@tab.labels} />
    </div>
    """
  end

  def draft(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-draft-dropdown">
            <div class="flex items-center">
              <.icon name="pencil-square" class="text-gray-400 mr-1 h-5 w-5" />
              <p class="text-gray-500">Draft Status</p>

              <.dropdown_clicky />
            </div>
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-draft-dropdown">
            <:description>
              Filter By Draft Status
            </:description>

            <.dropdown_toggle_list name="draft-status" items={@draft_statuses}>
              <:row :let={status}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.draft_status_selected?(@tab, status.value) do %>
                      <.icon name="check" class="text-teal-700 h-5 w-5" />
                    <% end %>
                  </div>
                  <span><%= format_draft_status(status.value) %></span>
                </div>
              </:row>
            </.dropdown_toggle_list>
          </.dropdown_menu>
        </div>
      </div>

      <.active_filter_items items={[%{draft_status: @tab.draft_status}]} />
    </div>
    """
  end

  def active_filter_items(assigns) do
    ~H"""
    <div class="flex flex-col space-y-1 text-sm">
      <.active_filter_title :for={item <- @items} item={item} />
    </div>
    """
  end

  def active_filter_title(%{item: %Mrgr.Schema.Repository{}} = assigns) do
    ~H"""
    <div class="flex space-x-1 items-center">
      <.language_icon language={@item.language} />
      <span><%= @item.name %></span>
    </div>
    """
  end

  def active_filter_title(%{item: %Mrgr.Schema.Member{}} = assigns) do
    ~H"""
    <.avatar member={@item} />
    """
  end

  def active_filter_title(%{item: %Mrgr.Schema.Label{}} = assigns) do
    ~H"""
    <.badge item={@item} />
    """
  end

  def active_filter_title(%{item: %{draft_status: status}} = assigns) do
    assigns =
      assigns
      |> assign(:title, format_draft_status(status))

    ~H"""
    <span><%= @title %></span>
    """
  end

  def format_draft_status("ready_for_review"), do: "Ready for Review"
  def format_draft_status(other), do: String.capitalize(other)

  def dropdown_clicky(assigns) do
    ~H"""
    <.icon name="chevron-down" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
    """
  end
end
