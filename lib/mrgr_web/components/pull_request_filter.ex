defmodule MrgrWeb.Components.PullRequestFilter do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI

  def filters(assigns) do
    ~H"""
    <div class="flex flex-col mt-2 space-y-3">
      <.aside>
        Customize your view by filtering on Author, Label, or Repository.
        <.l phx-click="delete-tab" data={[confirm: "Sure about that?"]}>
          delete tab
        </.l>
      </.aside>
      <.h3>Filters</.h3>
      <.repositories selected_tab={@selected_tab} repos={@repos} />
      <.labels selected_tab={@selected_tab} labels={@labels} />
      <.authors selected_tab={@selected_tab} items={@members} />
      <.draft selected_tab={@selected_tab} draft_statuses={@draft_statuses} />
      <.reviewers selected_tab={@selected_tab} items={@members} />
    </div>
    """
  end

  def authors(assigns) do
    ~H"""
    <div class="flex items-center">
      <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />

      <div class="flex flex-wrap -mb-px text-sm font-medium text-center items-center" role="tablist">
        <div :for={author <- @selected_tab.authors} class="mr-2" role="presentation">
          <.pr_filter item={author} />
        </div>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-author-dropdown">
            <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-author-dropdown">
            <:description>
              Filter By Author
            </:description>

            <.dropdown_toggle_list name="author" items={@items}>
              <:row :let={author}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.author_present?(@selected_tab, author) do %>
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
    </div>
    """
  end

  def reviewers(assigns) do
    ~H"""
    <div class="flex items-center">
      <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />

      <div class="flex flex-wrap -mb-px text-sm font-medium text-center items-center" role="tablist">
        <div :for={reviewers <- @selected_tab.reviewers} class="mr-2" role="presentation">
          <.pr_filter item={reviewers} />
        </div>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-reviewer-dropdown">
            <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
          </.dropdown_toggle_link>

          <.dropdown_menu name="pr-tab-reviewer-dropdown">
            <:description>
              Filter By Reviewer
            </:description>

            <.dropdown_toggle_list name="reviewer" items={@items}>
              <:row :let={reviewer}>
                <div class="flex items-center">
                  <div class="w-8">
                    <%= if Mrgr.PRTab.reviewer_present?(@selected_tab, reviewer) do %>
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
    </div>
    """
  end

  def repositories(assigns) do
    ~H"""
    <div class="flex items-center">
      <.repository_icon />

      <div class="relative">
        <div class="flex flex-wrap -mb-px text-sm font-medium text-center items-center" role="tablist">
          <div :for={repo <- @selected_tab.repositories} class="mr-2" role="presentation">
            <.pr_filter item={repo} />
          </div>

          <div class="relative">
            <.dropdown_toggle_link target="pr-tab-repository-dropdown">
              <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
            </.dropdown_toggle_link>

            <.dropdown_menu name="pr-tab-repository-dropdown">
              <:description>
                Filter By Repository
              </:description>

              <.dropdown_toggle_list name="repository" items={@repos}>
                <:row :let={repo}>
                  <div class="flex items-center">
                    <div class="w-8">
                      <%= if Mrgr.PRTab.repository_present?(@selected_tab, repo) do %>
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
      </div>
    </div>
    """
  end

  def labels(assigns) do
    ~H"""
    <div class="flex items-center">
      <.icon name="tag" class="text-gray-400 mr-1 h-5 w-5" />

      <div class="relative">
        <div class="flex flex-wrap -mb-px text-sm font-medium text-center items-center" role="tablist">
          <div :for={label <- @selected_tab.labels} class="mr-2" role="presentation">
            <.pr_filter item={label} />
          </div>

          <div class="relative">
            <.dropdown_toggle_link target="pr-tab-label-dropdown">
              <.icon name="ellipsis-horizontal" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
            </.dropdown_toggle_link>

            <.dropdown_menu name="pr-tab-label-dropdown">
              <:description>
                Filter By Label
              </:description>

              <.dropdown_toggle_list name="label" items={@labels}>
                <:row :let={label}>
                  <div class="flex items-center">
                    <div class="w-8">
                      <%= if Mrgr.PRTab.label_present?(@selected_tab, label) do %>
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
      </div>
    </div>
    """
  end

  def draft(assigns) do
    ~H"""
    <div class="flex items-center">
      <.icon name="pencil-square" class="text-gray-400 mr-1 h-5 w-5" />

      <.form :let={f} for={%{}} as={:tab} phx-change="update-draft-selection">
        <%= select(f, :draft_status, @draft_statuses,
          selected: @selected_tab.draft_status,
          class:
            "py-1.5 px-0 w-16 text-sm bg-transparent border-0 focus:outline-none focus:ring-0 focus:border-teal-500"
        ) %>
      </.form>
    </div>
    """
  end

  def pr_filter(assigns) do
    ~H"""
    <div class="flex items-center p-1 m-1 rounded-t-lg">
      <.pr_filter_title item={@item} />
    </div>
    """
  end

  def pr_filter_title(%{item: %Mrgr.Schema.Repository{}} = assigns) do
    ~H"""
    <%= @item.name %>
    """
  end

  def pr_filter_title(%{item: %Mrgr.Schema.Member{}} = assigns) do
    ~H"""
    <.avatar member={@item} />
    """
  end

  def pr_filter_title(%{item: %Mrgr.Schema.Label{}} = assigns) do
    ~H"""
    <.badge item={@item} />
    """
  end
end
