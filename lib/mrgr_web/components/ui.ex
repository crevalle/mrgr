defmodule MrgrWeb.Components.UI do
  use MrgrWeb, :component

  import MrgrWeb.JS
  import MrgrWeb.Components.Core

  alias Phoenix.LiveView.JS

  def inline_link(assigns) do
    default_class = "text-teal-700 hover:text-teal-500"
    class = Map.get(assigns, :class, default_class)
    href = Map.get(assigns, :href, "#")

    extra = assigns_to_attributes(assigns, [:href, :class])

    assigns =
      assigns
      |> assign(:href, href)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <a href={@href} class={@class} {@extra}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def l(assigns) do
    default_colors = "text-teal-700 hover:text-teal-500"
    default_class = "#{Map.get(assigns, :colors, default_colors)} font-light text-sm"
    class = Map.get(assigns, :class, default_class)
    href = Map.get(assigns, :href, "#")

    extra = assigns_to_attributes(assigns, [:href, :class])

    assigns =
      assigns
      |> assign(:href, href)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <a href={@href} class={@class} {@extra}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def dangerous_link(assigns) do
    default_class = "text-rose-600 hover:text-rose-500 font-light text-sm"
    class = Map.get(assigns, :class, default_class)
    href = Map.get(assigns, :href, "#")

    extra = assigns_to_attributes(assigns, [:href, :class])

    assigns =
      assigns
      |> assign(:href, href)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <a href={@href} class={@class} {@extra}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def aside(assigns) do
    ~H"""
    <span class="text-sm text-gray-400">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  def h1(assigns) do
    ~H"""
    <h1 class="text-xl font-semibold text-gray-900">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  def h3(assigns) do
    color = assigns[:color] || "text-gray-900"

    assigns = assign(assigns, :color, color)

    ~H"""
    <h3 class={"text-lg leading-6 font-medium #{@color}"}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  def subheading(assigns) do
    assigns =
      assigns
      |> assign_new(:description, fn -> [] end)

    ~H"""
    <.h3><%= @title %></.h3>
    <%= unless Enum.empty?(@description) do %>
      <p class="mt-1 mb-2">
        <%= render_slot(@description) %>
      </p>
    <% end %>
    """
  end

  def copy_button(assigns) do
    ~H"""
    <.button
      class="bg-blue-600 hover:bg-blue-700 focus:ring-blue-500"
      phx-click={Phoenix.LiveView.JS.dispatch("mrgr:clipcopy", to: @target)}
    >
      Copy to Clipboard
    </.button>
    """
  end

  def heading(assigns) do
    assigns = assign_new(assigns, :description, fn -> nil end)

    ~H"""
    <div class="">
      <.h1><%= @title %></.h1>
      <%= if @description do %>
        <p class="mt-2 text-sm text-gray-700"><%= @description %></p>
      <% end %>
    </div>
    """
  end

  def heading_description(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-gray-700"><%= render_slot(@inner_block) %></p>
    """
  end

  def th(assigns) do
    uppercase = if assigns[:uppercase], do: "uppercase", else: nil

    class = "px-3 py-3.5 text-left text-sm font-semibold text-gray-900 #{uppercase}"

    # <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Pattern</th>
    assigns = assign(assigns, :class, class)

    ~H"""
    <th scope="col" class={@class}>
      <%= render_slot(@inner_block) %>
    </th>
    """
  end

  def tr(assigns) do
    striped = if assigns[:striped], do: "even:bg-white odd:bg-gray-50", else: nil

    class = "border-t border-gray-300 py-2 #{striped}"

    assigns = assign(assigns, :class, class)

    ~H"""
    <tr class={@class}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  def td(assigns) do
    class = "whitespace-nowrap px-3 text-gray-700 #{assigns[:class]}"

    assigns = assign(assigns, :class, class)

    ~H"""
    <td class={@class}>
      <%= render_slot(@inner_block) %>
    </td>
    """
  end

  def table_attr(assigns) do
    label =
      assigns.key
      |> to_string()
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    value =
      case Map.get(assigns.obj, assigns.key) do
        %DateTime{} = dt ->
          ts(dt, assigns.tz)

        map when is_map(map) ->
          Jason.encode!(map, pretty: true)

        list when is_list(list) ->
          Enum.join(list, ", ")

        simple ->
          simple
      end

    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:value, value)

    ~H"""
    <.tr striped={true}>
      <.td class="font-bold"><%= @label %></.td>
      <.td><%= @value %></.td>
    </.tr>
    """
  end

  def installation_table(assigns) do
    ~H"""
    <table class="min-w-full">
      <.table_attr obj={@installation} key={:app_id} . />
      <.table_attr obj={@installation} key={:app_slug} . />
      <.table_attr obj={@installation} key={:events} . />
      <.table_attr obj={@installation} key={:external_id} . />
      <.table_attr obj={@installation} key={:html_url} . />
      <.table_attr obj={@installation} key={:installation_created_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:permissions} . />
      <.table_attr obj={@installation} key={:repositories_url} . />
      <.table_attr obj={@installation} key={:repository_selection} . />
      <.table_attr obj={@installation} key={:target_id} . />
      <.table_attr obj={@installation} key={:target_type} . />
      <.table_attr obj={@installation} key={:access_tokens_url} . />
      <.table_attr obj={@installation} key={:token} tz={@tz} . />
      <.table_attr obj={@installation} key={:token_expires_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:updated_at} tz={@tz} . />
      <.table_attr obj={@installation} key={:inserted_at} tz={@tz} . />
    </table>
    """
  end

  def admin_user_table(assigns) do
    ~H"""
    <table class="min-w-full">
      <thead class="bg-white">
        <tr>
          <.th uppercase={true}>ID</.th>
          <.th uppercase={true}>Current Installation</.th>
          <.th uppercase={true}>nickname</.th>
          <.th uppercase={true}>Full Name</.th>
          <.th uppercase={true}>last Seen</.th>
          <.th uppercase={true}>created</.th>
          <.th uppercase={true}>updated</.th>
        </tr>
      </thead>

      <%= for user <- @users do %>
        <.tr striped={true}>
          <.td>
            <%= link(user.id,
              to: Routes.admin_user_path(MrgrWeb.Endpoint, :show, user.id),
              class: "text-teal-700 hover:text-teal-500"
            ) %>
          </.td>
          <.td><%= link_to_installation(user) %></.td>
          <.td><%= user.nickname %></.td>
          <.td><%= user.name %></.td>
          <.td><%= ts(user.last_seen_at, @tz) %></.td>
          <.td><%= ts(user.inserted_at, @tz) %></.td>
          <.td><%= ts(user.updated_at, @tz) %></.td>
        </.tr>
      <% end %>
    </table>
    """
  end

  def link_to_installation(user) do
    title = current_account(user)
    installation_id = user.current_installation_id

    opts = [
      to: Routes.admin_installation_path(MrgrWeb.Endpoint, :show, installation_id),
      class: "text-teal-700 hover:text-teal-500"
    ]

    link(title, opts)
  end

  defp current_account(%{current_installation: %{account: %{login: login}}}), do: login
  defp current_account(user), do: user.current_installation_id

  def nav_item(assigns) do
    link_defaults = [
      to: assigns.route,
      class:
        "text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center px-2 py-2 text-sm font-medium rounded-md"
    ]

    link_opts = assigns[:link_opts] || []
    link_opts = Keyword.merge(link_defaults, link_opts)

    assigns =
      assigns
      |> assign(:link_opts, link_opts)
      |> assign_new(:inner_block, fn -> [] end)

    ~H"""
    <%= link @link_opts do %>
      <.icon name={@icon} class="text-gray-400 group-hover:text-gray-500 mr-3 flex-shrink-0 h-6 w-6" />
      <span class="flex-1"><%= @label %></span>

      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def timeago(assigns) do
    color =
      case assigns[:uhoh] do
        true ->
          uhoh_color(assigns.datetime)

        false ->
          "text-gray-500"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={@color}>
      <time datetime={@datetime}><%= ago(@datetime) %></time> ago
    </span>
    """
  end

  def language_icon(%{language: nil} = assigns) do
    ~H"""
    <span class="mr-5"></span>
    """
  end

  def language_icon(assigns) do
    name =
      assigns.language
      |> String.downcase()
      |> String.replace("-", "")

    src = language_icon_url(name)

    assigns = assign(assigns, :src, src)

    ~H"""
    <span>
      <img src={@src} class="h-5 w-5" />
    </span>
    """
  end

  def close_detail_pane(assigns) do
    assigns = assign_new(assigns, :phx_click, fn -> %Phoenix.LiveView.JS{} end)

    ~H"""
    <button phx-click={hide_detail(@phx_click)} colors="outline-none">
      <.icon name="x-circle" class="text-teal-700 hover:text-teal-500 mr-1 h-5 w-5" />
    </button>
    """
  end

  def page_nav(%{page: []} = assigns) do
    ~H"""

    """
  end

  def page_nav(%{page: %{total_pages: 1}} = assigns) do
    ~H"""

    """
  end

  def page_nav(assigns) do
    ~H"""
    <nav class="">
      <ul class="flex my-2">
        <li class="">
          <a
            class={"px-2 py-2 #{if @page.page_number <= 1, do: "pointer-events-none text-gray-600", else: "text-teal-700 hover:text-teal-500"}"}
            href="#"
            phx-click="paginate"
            phx-value-page={@page.page_number - 1}
          >
            Previous
          </a>
        </li>
        <%= for idx <-  Enum.to_list(1..@page.total_pages) do %>
          <li class="">
            <a
              class={"px-2 py-2 #{if @page.page_number == idx, do: "pointer-events-none text-teal-400", else: "text-teal-700 hover:text-teal-500"}"}
              href="#"
              phx-click="paginate"
              phx-value-page={idx}
            >
              <%= idx %>
            </a>
          </li>
        <% end %>
        <li class="">
          <a
            class={"px-2 py-2 #{if @page.page_number >= @page.total_pages, do: "pointer-events-none text-gray-600", else: "text-teal-700 hover:text-teal-500"}"}
            href="#"
            phx-click="paginate"
            phx-value-page={@page.page_number + 1}
          >
            Next
          </a>
        </li>
      </ul>
    </nav>
    """
  end

  def spinner(assigns) do
    ~H"""
    <div
      id={@id}
      class="hidden spinner"
      data-spinning={show_spinner(@id)}
      data-done={hide_spinner(@id)}
    >
      <div class="bounce1"></div>
      <div class="bounce2"></div>
      <div class="bounce3"></div>
    </div>
    """
  end

  def installation_synced_at(assigns) do
    ~H"""
    <p class="text-sm italic text-gray-500">
      Data last synced at <%= if @dt, do: ts(@dt, @timezone), else: "--" %>
    </p>
    """
  end

  def pr_tab(assigns) do
    selected =
      case assigns.selected? do
        true -> "selected"
        false -> ""
      end

    class = ~w(
      flex
      items-center
      tab-select-button
      #{selected}
    )

    assigns =
      assigns
      |> assign(:class, class)

    ~H"""
    <div
      class={@class}
      phx-click={JS.push("select-tab", value: %{id: @tab.id})}
      id={"#{@tab.id}-tab"}
      role="tab"
      aria-selected="false"
      role="presentation"
    >
      <h2>
        <%= @tab.title || "untitled" %>
      </h2>
      <.pr_count_badge items={@tab.pull_requests} />
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

  def to_days(assigns) do
    ~H"""
    <%= Float.round(@hours / 24, 1) %> days
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

  def dropdown(assigns) do
    ~H"""
    <div class="dropdown relative inline-block">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def dropdown_list(assigns) do
    ~H"""
    <div class="dropdown-content hidden absolute z-1 overflow-visible w-max rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def dropdown_menu(assigns) do
    ~H"""
    <div
      style="display: none;"
      id={@name}
      phx-click-away={JS.hide(transition: toggle_out_transition())}
      class="origin-top-right z-50 absolute rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
      role="menu"
      aria-orientation="vertical"
      aria-labelledby={"#{@name}-toggle"}
      tabindex="-1"
    >
      <div class="mt-2 w-max flex flex-col text-sm sm:mt-0 divide-y divide-gray-100">
        <p class="text-center text-gray-500 p-2">
          <%= render_slot(@description) %>
        </p>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def dropdown_toggle_link(assigns) do
    ~H"""
    <.inline_link
      phx-click={toggle(to: "##{@target}")}
      id={"#{@target}-toggle"}
      aria-expanded="false"
      aria-haspopup="true"
    >
      <%= render_slot(@inner_block) %>
    </.inline_link>
    """
  end

  def dropdown_toggle_list(assigns) do
    id_prefix =
      [Map.get(assigns, :ctx), assigns.name]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("-")

    assigns =
      assigns
      |> assign_new(:value, fn -> %{} end)
      |> assign(:id_prefix, id_prefix)

    ~H"""
    <div class="flex flex-col">
      <.l
        :for={item <- @items}
        id={"#{@id_prefix}-#{item.id}"}
        phx_click={JS.push("toggle-#{@name}", value: Map.merge(%{id: item.id}, @value))}
        class="text-gray-700 p-2 text-sm w-52 rounded-md hover:bg-gray-50"
        role="menuitem"
        tabindex="-1"
      >
        <%= for row <- @row do %>
          <%= render_slot(row, item) %>
        <% end %>
      </.l>
    </div>
    """
  end

  def snooze_blurb(%{tab: %{viewing_snoozed: true}} = assigns) do
    ~H"""
    <div class="p-4 max-w-xl bg-blue-100 rounded-md border border-1">
      <p class="text-gray-400 italic">
        😴 You're viewing snoozed PRs.
        <.l phx-click="toggle-viewing-snoozed">Show Unsnoozed</.l>
      </p>
    </div>
    """
  end

  def snooze_blurb(%{tab: %{snoozed: %{total_entries: e}}} = assigns) when e > 0 do
    ~H"""
    <div class="p-4 max-w-xl bg-blue-100 rounded-md border border-1">
      <p class="text-gray-400 italic">
        <%= @tab.snoozed.total_entries %> pull requests are snoozed.
        <.l phx-click="toggle-viewing-snoozed">Show Them</.l>
      </p>
    </div>
    """
  end

  def snooze_blurb(assigns) do
    ~H"""

    """
  end

  def pr_count_badge(%{items: []} = assigns) do
    ~H"""
    <.pr_count_badge count="-" />
    """
  end

  def pr_count_badge(%{items: %{total_entries: 0}} = assigns) do
    ~H"""

    """
  end

  def pr_count_badge(%{items: %{total_entries: entries}} = assigns) do
    assigns = assign(assigns, :count, entries)

    ~H"""
    <.pr_count_badge count={@count} />
    """
  end

  def pr_count_badge(%{count: _count} = assigns) do
    ~H"""
    <span class="bg-gray-100 group-hover:bg-gray-200 ml-3 inline-block py-0.5 px-3 text-xs font-medium rounded-full">
      <%= @count %>
    </span>
    """
  end

  def badges(assigns) do
    ~H"""
    <div class="mt-2 flex flex-wrap items-center space-x-2 text-sm text-gray-500 sm:mt-0">
      <.badge :for={alert <- Mrgr.FileChangeAlert.for_pull_request(@pull_request)} item={alert} />
      <.badge :for={label <- @pull_request.labels} item={label} />
    </div>
    """
  end

  def badge(assigns) do
    ~H"""
    <span
      style={"background-color: #{@item.color};"}
      class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full text-gray-900"
    >
      <%= @item.name %>
    </span>
    """
  end

  def avatar(assigns) do
    ~H"""
    <div class="flex items-center">
      <%= img_tag(@member.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
      <%= @member.login %>
    </div>
    """
  end

  def preview_comment(assigns) do
    ~H"""
    <div>
      <div class="float-left">
        <div class="flex">
          <%= img_tag(Mrgr.Schema.Comment.author(@comment).avatar_url,
            class: "rounded-xl h-5 w-5 mr-1"
          ) %>
        </div>
      </div>
      <p class="text-gray-500 italic text-sm ">
        <%= Mrgr.Schema.Comment.body(@comment) %>
      </p>
    </div>
    """
  end

  def frozen_repo_list(assigns) do
    ~H"""
    <div class="flex flex-col my-4 p-4 rounded-md border border-blue-700 bg-blue-50">
      <.h3 color="text-blue-600">❄️ There is a Merge Freeze in effect❄️</.h3>
      <p class="my-3">PR merging is disabled for the following repos:</p>

      <ul class="list-disc my-3 mx-6">
        <li :for={r <- @repos}>
          <%= r.name %>
        </li>
      </ul>

      <p class="my-3">To resume merging for these repos, disable the Merge Freeze.</p>
    </div>
    """
  end

  def merge_freeze_menu(assigns) do
    ~H"""
    <div class="relative inline-block text-left">
      <div>
        <.outline_button
          phx-click={
            JS.toggle(
              to: "#merge-freeze-menu",
              in:
                {"transition ease-out duration-100", "transform opacity-0 scale-95",
                 "transform opacity-100 scale-100"},
              out:
                {"transition ease-in duration-75", "transform opacity-100 scale-100",
                 "transform opacity-0 scale-95"}
            )
          }
          class="text-gray-700 border-gray-300 hover:bg-gray-100"
          id="freeze-menu-button"
          aria-expanded="false"
          aria-haspopup="true"
        >
          Freeze Merging <.icon name="chevron-down" class="-mr-1 ml-2 h-5 w-5" />
        </.outline_button>
      </div>

      <div
        style="display: none;"
        id="merge-freeze-menu"
        class="origin-top-right absolute right-0 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="freeze-menu-button"
        tabindex="-1"
      >
        <div class="py-1" role="none">
          <.l
            :for={r <- @repos}
            id={"repo-menu-item-#{r.id}"}
            phx_click="toggle-merge-freeze"
            phx_value_repo_id={r.id}
            data_confirm="Sure about that?"
            class="text-gray-700 block my-2 text-sm outline-none"
            role="menuitem"
            tabindex="-1"
          >
            <div class="flex items-center hover:bg-gray-50">
              <div class="basis-8 text-blue-400 ml-2">
                <%= if r.merge_freeze_enabled do %>
                  ❄️
                <% end %>
              </div>
              <%= r.name %>
            </div>
          </.l>
        </div>
      </div>
    </div>
    """
  end

  def repository_icon(assigns) do
    ~H"""
    <%= img_tag("images/repository-32.png", class: "opacity-40 h-5 w-5") %>
    """
  end

  defp language_icon_url("html" = name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}5/#{name}5-original.svg"
  end

  defp language_icon_url("objectivec" = name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}/#{name}-plain.svg"
  end

  defp language_icon_url(name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}/#{name}-original.svg"
  end
end
