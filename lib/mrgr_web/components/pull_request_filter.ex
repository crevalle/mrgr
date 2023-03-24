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

      <.h3>Custom Filters</.h3>

      <div class="flex items-start space-x-8">
        <.repositories selected_tab={@selected_tab} repos={@repos} />
        <.labels selected_tab={@selected_tab} labels={@labels} />
        <.authors selected_tab={@selected_tab} items={@members} />
        <.draft selected_tab={@selected_tab} draft_statuses={@draft_statuses} />
        <.reviewers selected_tab={@selected_tab} items={@members} />
      </div>
    </div>
    """
  end

  def authors(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />
        <p class="text-gray-500">Authors</p>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-author-dropdown">
            <.dropdown_clicky />
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

      <.active_filter_items items={@selected_tab.authors} />
    </div>
    """
  end

  def reviewers(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <.icon name="users" class="text-gray-400 mr-1 h-5 w-5" />
        <p class="text-gray-500">Reviewers</p>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-reviewer-dropdown">
            <.dropdown_clicky />
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

      <.active_filter_items items={@selected_tab.reviewers} />
    </div>
    """
  end

  def repositories(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <.repository_icon />
        <p class="text-gray-500">Repositories</p>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-repository-dropdown">
            <.dropdown_clicky />
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

      <.active_filter_items items={@selected_tab.repositories} />
    </div>
    """
  end

  def labels(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <div class="flex items-center">
        <.icon name="tag" class="text-gray-400 mr-1 h-5 w-5" />
        <p class="text-gray-500">Labels</p>

        <div class="relative">
          <.dropdown_toggle_link target="pr-tab-label-dropdown">
            <.dropdown_clicky />
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

      <.active_filter_items items={@selected_tab.labels} />
    </div>
    """
  end

  def draft(assigns) do
    ~H"""
    <div>
      <div class="flex items-center">
        <.icon name="pencil-square" class="text-gray-400 mr-1 h-5 w-5" />
        <p class="text-gray-500">Draft Status</p>

        <.form :let={f} for={%{}} as={:tab} phx-change="update-draft-selection" class="ml-2">
          <%= select(f, :draft_status, @draft_statuses,
            selected: @selected_tab.draft_status,
            class:
              "p-0 w-16 text-sm bg-transparent border-0 focus:outline-none focus:ring-0 focus:border-teal-500"
          ) %>
        </.form>
      </div>
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

  def dropdown_clicky(assigns) do
    ~H"""
    <.icon name="chevron-down" class="text-gray-500 -mr-1 ml-2 h-5 w-5" />
    """
  end
end
