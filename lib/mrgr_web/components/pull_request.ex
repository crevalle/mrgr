defmodule MrgrWeb.Components.PullRequest do
  use MrgrWeb, :component

  import MrgrWeb.Components.UI
  import MrgrWeb.Components.Core

  alias Mrgr.Schema.PullRequest
  alias Phoenix.LiveView.JS

  def render_detail(%{item: %Mrgr.Schema.PullRequest{}} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-6 bg-white rounded-md">
      <.pull_request_detail pull_request={@item} attr={@attr} timezone={@timezone} />
    </div>
    """
  end

  def render_detail(%{item: %Mrgr.Schema.PRTab{}} = assigns) do
    ~H"""
    <div class="flex flex-col space-y-6 bg-white rounded-md">
      <.pr_tab_form tab={@item} />
    </div>
    """
  end

  def pull_request_detail(%{attr: "comments"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        Comments (<%= Enum.count(@pull_request.comments) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_comment :for={comment <- @pull_request.comments} comment={comment} tz={@timezone} />
      </div>
    </.detail_content>
    """
  end

  def pull_request_detail(%{attr: "commits"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        Commits (<%= Enum.count(@pull_request.commits) %>)
      </:title>

      <div class="flex flex-col space-y-4 divide-y divide-gray-200">
        <.render_commit :for={commit <- @pull_request.commits} commit={commit} tz={@timezone} />
      </div>
    </.detail_content>
    """
  end

  def pull_request_detail(%{attr: "files-changed"} = assigns) do
    ~H"""
    <.detail_content>
      <:title>
        Files Changed (<%= Enum.count(@pull_request.files_changed) %>)
      </:title>
      <div class="flex flex-col space-y-0 leading-tight">
        <.changed_file
          :for={f <- @pull_request.files_changed}
          filename={f}
          alerts={@pull_request.repository.file_change_alerts}
        />
      </div>
    </.detail_content>
    """
  end

  def detail_content(assigns) do
    ~H"""
    <div class="flex flex-col space-y-4">
      <div class="flex justify-between items-start">
        <.h3>
          <%= render_slot(@title) %>
        </.h3>
        <.close_detail_pane phx_click={JS.push("hide-detail")} />
      </div>

      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def changed_file(assigns) do
    matching_alert =
      Enum.find(
        assigns.alerts,
        &Mrgr.FileChangeAlert.pattern_matches_filename?(assigns.filename, &1)
      )

    color =
      case matching_alert do
        nil -> "transparent"
        alert -> alert.color
      end

    assigns =
      assigns
      |> assign(:color, color)

    ~H"""
    <div style={"border-color: #{@color};"} class="border-l-2"><pre><%= @filename %></pre></div>
    """
  end

  def reviewers(%{reviewers: []} = assigns) do
    ~H"""
    <span class="text-gray-500 italic text-sm">none</span>
    """
  end

  def reviewers(assigns) do
    assigns =
      assigns
      |> assign(:count, Enum.count(assigns.reviewers))

    ~H"""
    <.reviewer
      :for={{reviewer, idx} <- Enum.with_index(@reviewers)}
      reviewer={reviewer}
      me={@current_user}
      comma={idx < @count - 1}
    />
    """
  end

  def reviewer(%{reviewer: %{login: login}, me: %{nickname: login}} = assigns) do
    ~H"""
    <span class="text-emerald-600 italic text-sm">
      <%= username(@reviewer) %><%= if @comma, do: "," %>
    </span>
    """
  end

  def reviewer(assigns) do
    ~H"""
    <span class="text-gray-500 italic text-sm">
      <%= username(@reviewer) %><%= if @comma, do: "," %>
    </span>
    """
  end

  def toggle_reviewer_menu(assigns) do
    ~H"""
    <div class="relative">
      <.dropdown_toggle_link target={"toggle-reviewer-dropdown-#{@pull_request.id}"}>
        <.icon name="ellipsis-horizontal" class="text-gray-500 mt-1 h-5 w-5" />
      </.dropdown_toggle_link>

      <.dropdown_menu name={"toggle-reviewer-dropdown-#{@pull_request.id}"}>
        <:description>
          Add or Remove Reviewers
        </:description>

        <.dropdown_toggle_list
          name="reviewer"
          items={@members}
          ctx={"pull-request-#{@pull_request.id}"}
          value={%{pull_request_id: @pull_request.id}}
        >
          <:row :let={member}>
            <div class="flex items-center">
              <div class="w-8">
                <%= if Mrgr.Schema.PullRequest.reviewer_requested?(@pull_request, member) do %>
                  <.icon name="check" class="text-teal-700 h-5 w-5" />
                <% end %>
              </div>
              <div class="flex">
                <%= img_tag(member.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
                <%= member.login %>
              </div>
            </div>
          </:row>
        </.dropdown_toggle_list>
      </.dropdown_menu>
    </div>
    """
  end

  def pr_approval_text(assigns) do
    num = Mrgr.Schema.PullRequest.required_approvals(assigns.pull_request)
    text = "#{assigns.pull_request.approving_review_count}/#{num} approvals"

    assigns = assign(assigns, :text, text)

    ~H"""
    <%= @text %>
    """
  end

  def preview_commit(assigns) do
    ~H"""
    <div class="flex justify-between items-center">
      <p class="truncate"><%= PullRequest.commit_message(@commit) %></p>
      <p class="text-sm text-gray-500 whitespace-nowrap">
        <%= PullRequest.commit_author_name(@commit) %>
      </p>
    </div>
    """
  end

  def render_commit(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <p><%= PullRequest.commit_message(@commit) %></p>
      <div class="flex flex-col">
        <div class="flex space-between space-x-2 divide-x divide-gray-500">
          <p class="text-sm text-gray-500 truncate">
            <%= shorten_sha(PullRequest.commit_sha(@commit)) %>
          </p>
          <p class="pl-2 text-sm text-gray-500"><%= ts(PullRequest.committed_at(@commit)) %></p>
        </div>
        <p class="text-sm text-gray-500"><%= PullRequest.commit_author_name(@commit) %></p>
      </div>
    </div>
    """
  end

  def render_comment(assigns) do
    ~H"""
    <div class="flex flex-col pt-2">
      <div class="flex flex-col">
        <.avatar member={Mrgr.Schema.Comment.author(@comment)} />
        <.aside><%= ts(@comment.posted_at, @tz) %></.aside>
      </div>
      <div class="pt-1">
        <p class="text-gray-500 italic">
          <%= Mrgr.Schema.Comment.body(@comment) %>
        </p>
      </div>
    </div>
    """
  end

  def filters(assigns) do
    ~H"""
    <div class="flex flex-col mt-2 space-y-3">
      <.h3>Filters</.h3>
      <.aside>
        Customize your view by filtering on Author, Label, or Repository.
        <.l phx-click="edit-tab">
          Edit Tab Details
        </.l>
      </.aside>
      <!-- repositories -->
      <div class="flex items-center">
        <%= img_tag("images/repository-32.png", class: "opacity-40 h-5 w-5") %>

        <div class="relative">
          <div
            class="flex flex-wrap -mb-px text-sm font-medium text-center items-center"
            role="tablist"
          >
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
      <!-- labels -->
      <div class="flex items-center">
        <.icon name="tag" class="text-gray-400 mr-1 h-5 w-5" />

        <div class="relative">
          <div
            class="flex flex-wrap -mb-px text-sm font-medium text-center items-center"
            role="tablist"
          >
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
      <!-- authors -->
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

              <.dropdown_toggle_list name="author" items={@members}>
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
    </div>
    """
  end

  def pr_tab_form(assigns) do
    ~H"""
    <.detail_content>
      <:title>
        Edit Tab Title
      </:title>
    </.detail_content>
    <div class="flex flex-col">
      <.form :let={f} for={:tab} phx-submit="update-tab">
        <div class="flex flex-col space-y-4">
          <%= text_input(f, :title,
            placeholder: "give this view a name",
            value: @tab.title,
            class: "w-full text-sm font-medium rounded-md text-gray-700 mt-px pt-2"
          ) %>

          <div class="flex justify-between items-center">
            <.dangerous_link phx-click="delete-tab" data={[confirm: "Sure about that?"]}>
              delete tab
            </.dangerous_link>
            <.button
              type="submit"
              phx-disable-with="Saving..."
              class="bg-teal-700 hover:bg-teal-600 focus:ring-teal-500"
            >
              Save
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
