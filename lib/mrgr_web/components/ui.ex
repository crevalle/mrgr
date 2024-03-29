defmodule MrgrWeb.Components.UI do
  use MrgrWeb, :component

  import MrgrWeb.JS
  import MrgrWeb.Components.Core

  alias Phoenix.LiveView.JS

  attr :close, :string, default: "close-detail"

  slot :title, required: true
  slot :inner_block, required: true

  def detail_column(assigns) do
    ~H"""
    <div class="bg-white rounded-md">
      <div class="flex flex-col space-y-4">
        <div class="flex justify-between items-center">
          <.h3>
            <%= render_slot(@title) %>
          </.h3>
          <.link phx-click={@close}>
            <.icon name="x-circle" class="text-teal-700 hover:text-teal-500 mr-1 h-5 w-5" />
          </.link>
        </div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def nav_bar(assigns) do
    ~H"""
    <div class="ml-4 flex items-center space-x-6">
      <.nav_item route={~p"/pull-requests"} icon="share" label="Open Pull Requests">
        <%= live_render(@conn, MrgrWeb.Live.OpenPRCountBadge,
          session: %{
            "user_id" => @current_user.id
          }
        ) %>
      </.nav_item>

      <.nav_item route={~p"/alerts"} icon="bell-alert" label="Realtime Alerts" . />

      <.nav_item route={~p"/changelog"} icon="book-open" label="Changelog" . />

      <p
        :if={Mrgr.Installation.trial_period?(@current_user.current_installation)}
        class="alert alert-info font-light text-sm"
      >
        Your trial expires in <%= Mrgr.Installation.trial_time_left(
          @current_user.current_installation
        ) %> days.
        <.link href={~p"/account"} class="underline">Upgrade</.link>
      </p>

      <p
        :if={!Mrgr.Installation.onboarded?(@current_user.current_installation)}
        class="alert alert-info"
      >
        Hey! We are still onboarding your data, please wait!
      </p>
    </div>
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
    <h1 class="text-3xl font-semibold text-gray-900">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  def h2(assigns) do
    ~H"""
    <h2 class="text-lg font-semibold text-gray-900">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true

  def h3(assigns) do
    ~H"""
    <h3 class={[
      "text-lg leading-6 font-medium",
      @class
    ]}>
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

  attr :title, :string, required: true
  slot :description

  def heading(assigns) do
    ~H"""
    <div class="flex flex-col space-y-2">
      <.h1><%= @title %></.h1>
      <p class="mt-2 text-sm text-gray-700 hide-empty"><%= render_slot(@description) %></p>
    </div>
    """
  end

  def heading_description(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-gray-700"><%= render_slot(@inner_block) %></p>
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

        bool when is_boolean(bool) ->
          tf(bool)

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
      <time datetime={@datetime}><%= ago(@datetime) %></time>
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

  def close_modal(assigns) do
    ~H"""
    <button phx-click={@action} colors="outline-none">
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

  attr :id, :string, required: true
  attr :class, :string, default: nil

  def spinner(assigns) do
    ~H"""
    <div
      id={@id}
      class={["spinner", @class]}
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

  def to_days(assigns) do
    ~H"""
    <%= Float.round(@hours / 24, 1) %> days
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
      class="dropdown-menu"
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

  attr :class, :string, default: nil
  attr :target, :string, required: true
  slot :inner_block

  def dropdown_toggle_link(assigns) do
    ~H"""
    <.l
      phx-click={toggle(to: "##{@target}")}
      id={"#{@target}-toggle"}
      aria-expanded="false"
      aria-haspopup="true"
      class={@class}
    >
      <%= render_slot(@inner_block) %>
    </.l>
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
        phx-click={JS.push("toggle-#{@name}", value: Map.merge(%{id: item.id}, @value))}
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

  def pr_count_badge(%{items: %{total_entries: entries}} = assigns) do
    assigns = assign(assigns, :count, entries)

    ~H"""
    <.pr_count_badge count={@count} />
    """
  end

  def pr_count_badge(%{items: items} = assigns) do
    assigns = assign(assigns, :count, Enum.count(items))

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

  attr :state, :string, required: true

  def subscription_state_badge(assigns) do
    color =
      case assigns.state do
        "trial" -> "alert-info"
        "active" -> "alert-sweet"
        "cancelled" -> "alert-warning"
        "personal" -> "alert-sweet"
        _ -> "alert-warning"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={[
      "px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
      @color
    ]}>
      <%= @state %>
    </span>
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

  def avatar(%{member: nil} = assigns) do
    ~H"""
    <div class="text-gray-400 italic">
      unknown
    </div>
    """
  end

  def avatar(assigns) do
    ~H"""
    <div class="flex items-center">
      <%= img_tag(@member.avatar_url, class: "rounded-xl h-5 w-5 mr-1") %>
      <%= login(@member) %>
    </div>
    """
  end

  def frozen_repo_list(assigns) do
    ~H"""
    <div class="flex flex-col my-4 p-4 rounded-md border border-blue-700 bg-blue-50">
      <.h3 class="text-blue-600">❄️ There is a Merge Freeze in effect❄️</.h3>
      <p class="my-3">PR merging is disabled for the following repos:</p>

      <ul class="list-disc my-3 mx-6">
        <li :for={r <- @repos}>
          <%= r.name %>
        </li>
      </ul>

      <p class="my-3">
        To resume merging for these repos,
        <.l href={~p"/repositories"}>disable the Merge Freeze</.l>.
      </p>
    </div>
    """
  end

  def repository_icon(assigns) do
    ~H"""
    <%= img_tag("/images/repository-32.png", class: "opacity-40 h-5 w-5") %>
    """
  end

  def profile_dropdown_menu(assigns) do
    ~H"""
    <div class="relative">
      <div>
        <button
          phx-click={
            Phoenix.LiveView.JS.toggle(
              to: "#user-menu",
              in:
                {"transition ease-out duration-100", "transform opacity-0 scale-95",
                 "transform opacity-100 scale-100"},
              out:
                {"transition ease-in duration-75", "transform opacity-100 scale-100",
                 "transform opacity-0 scale-95"}
            )
          }
          phx-click-away={
            Phoenix.LiveView.JS.hide(
              to: "#user-menu",
              transition: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
            )
          }
          class="inline-flex items-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-gray-500 hover:bg-stone-50 focus:outline-none focus:ring-2 focus:ring-offset-2 bg-white focus:ring-indigo-500"
          id="user-menu-button"
          aria-expanded="false"
          aria-haspopup="true"
        >
          <span class="sr-only">Open user menu</span>

          <p class="flex space-x-2 items-center">
            <%= img_tag(Mrgr.Schema.User.image(@current_user),
              class: "h-8 w-8 rounded-full",
              alt: @current_user.name
            ) %>
            <.icon name="chevron-down" class="h-5 w-5" />
          </p>
        </button>
      </div>

      <div
        id="user-menu"
        style="display: none;"
        class="origin-top-right absolute right-0 mt-2 w-48 z-50 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none divide-y divide-gray-100"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="user-menu-button"
        tabindex="-1"
      >
        <.admin_nav_menu :if={@admin} />

        <div>
          <a
            href={~p"/repositories"}
            class="text-gray-600 hover:text-gray-900 hover:bg-gray-50 group flex items-center space-x-2 px-2 py-2 text-sm font-medium rounded-md"
          >
            <%= img_tag("/images/repository-32.png", class: "opacity-40 h-6 w-6") %>
            <span class="pl-1">Repositories</span>
          </a>
          <.nav_item route={~p"/account"} icon="banknotes" label="Account" . />
        </div>
        <div class="py-1">
          <.nav_item
            route={Routes.auth_path(MrgrWeb.Endpoint, :delete)}
            link_opts={[method: "delete", data_confirm: "Ready to go?"]}
            icon="arrow-right-on-rectangle"
            label="Sign Out"
            .
          />
        </div>
      </div>
    </div>
    """
  end

  def admin_nav_menu(assigns) do
    ~H"""
    <div class="py-1">
      <div class="flex justify-center">
        <p class="text-gray-600">🍣 ADMIN 🍣</p>
      </div>
      <.nav_item
        route={Routes.oban_dashboard_path(MrgrWeb.Endpoint, :home)}
        icon="circle-stack"
        label="Oban Background Jobs"
        .
      />

      <.nav_item
        route={Routes.admin_github_api_request_path(MrgrWeb.Endpoint, :index)}
        icon="cloud-arrow-up"
        label="Github API Requests"
        .
      />

      <.nav_item
        route={Routes.admin_incoming_webhook_path(MrgrWeb.Endpoint, :index)}
        icon="phone-arrow-down-left"
        label="Incoming Webhooks"
        .
      />

      <.nav_item
        route={Routes.admin_stripe_webhook_path(MrgrWeb.Endpoint, :index)}
        icon="currency-dollar"
        label="Stripe Webhooks"
        .
      />

      <.nav_item
        route={Routes.admin_installation_path(MrgrWeb.Endpoint, :index)}
        icon="globe-alt"
        label="Installations"
        .
      />

      <.nav_item
        route={Routes.admin_subscription_path(MrgrWeb.Endpoint, :index)}
        icon="newspaper"
        label="Subscriptions"
        .
      />

      <.nav_item
        route={Routes.admin_user_path(MrgrWeb.Endpoint, :index)}
        icon="users"
        label="Users"
        .
      />

      <.nav_item
        route={Routes.admin_waiting_list_signup_path(MrgrWeb.Endpoint, :index)}
        icon="sparkles"
        label="Waiting List Signups"
        .
      />
    </div>
    """
  end

  attr :user_id, :integer
  slot :inner_block

  def slack_button(assigns) do
    ~H"""
    <a
      href={"https://slack.com/oauth/v2/authorize?scope=chat:write,im:write&client_id=#{Application.get_env(:mrgr, :slack)[:client_id]}&state=#{@user_id}"}
      style="align-items:center;color:#fff;background-color:#4A154B;border:0;border-radius:44px;display:inline-flex;font-family:Lato, sans-serif;font-size:14px;font-weight:600;height:40px;justify-content:center;text-decoration:none;width:204px"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        style="height:16px;width:16px;margin-right:12px"
        viewBox="0 0 122.8 122.8"
      >
        <path
          d="M25.8 77.6c0 7.1-5.8 12.9-12.9 12.9S0 84.7 0 77.6s5.8-12.9 12.9-12.9h12.9v12.9zm6.5 0c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9v32.3c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V77.6z"
          fill="#e01e5a"
        >
        </path>
        <path
          d="M45.2 25.8c-7.1 0-12.9-5.8-12.9-12.9S38.1 0 45.2 0s12.9 5.8 12.9 12.9v12.9H45.2zm0 6.5c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H12.9C5.8 58.1 0 52.3 0 45.2s5.8-12.9 12.9-12.9h32.3z"
          fill="#36c5f0"
        >
        </path>
        <path
          d="M97 45.2c0-7.1 5.8-12.9 12.9-12.9s12.9 5.8 12.9 12.9-5.8 12.9-12.9 12.9H97V45.2zm-6.5 0c0 7.1-5.8 12.9-12.9 12.9s-12.9-5.8-12.9-12.9V12.9C64.7 5.8 70.5 0 77.6 0s12.9 5.8 12.9 12.9v32.3z"
          fill="#2eb67d"
        >
        </path>
        <path
          d="M77.6 97c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9-12.9-5.8-12.9-12.9V97h12.9zm0-6.5c-7.1 0-12.9-5.8-12.9-12.9s5.8-12.9 12.9-12.9h32.3c7.1 0 12.9 5.8 12.9 12.9s-5.8 12.9-12.9 12.9H77.6z"
          fill="#ecb22e"
        >
        </path>
      </svg>
      <%= render_slot(@inner_block) || "Install Mrgr Slackbot" %>
    </a>
    """
  end

  def notification_preference_icon(assigns) do
    ~H"""
    <div class="tooltip pl-2">
      <%= render_slot(@inner_block) %>
      <span class="tooltiptext">
        <%= render_slot(@tooltip) %>
      </span>
    </div>
    """
  end

  def slack_enabled_icon(assigns) do
    ~H"""
    <%= img_tag("/images/Slack-mark-RGB.png", class: "w-4 h-4 toggle") %>
    """
  end

  def slack_disabled_icon(assigns) do
    ~H"""
    <%= img_tag("/images/Slack-mark-black-RGB.png", class: "w-4 h-4 opacity-40 toggle") %>
    """
  end

  def email_enabled_icon(assigns) do
    ~H"""
    <.icon name="envelope" class="h-4 w-4 text-green-500 toggle" />
    """
  end

  def email_disabled_icon(assigns) do
    ~H"""
    <.icon name="envelope" class="h-4 w-4 toggle text-gray-400" />
    """
  end

  def channel_icon(%{channel: "email"} = assigns), do: email_enabled_icon(assigns)
  def channel_icon(%{channel: "slack"} = assigns), do: slack_enabled_icon(assigns)

  def hif_pattern(assigns) do
    ~H"""
    <pre class="text-sm font-medium text-gray-900"><%= @pattern %></pre>
    """
  end

  def slack_connection_status(%{connected: false} = assigns) do
    ~H"""
    <div class="flex items-center space-x-1 pt-3">
      <%= img_tag("/images/Slack-mark-RGB.png", class: "w-4 h-4") %>
      <p>Slack Unconnected</p>
      <.icon name="x-circle" type="solid" class="text-red-600 h-5 w-5" />
    </div>
    """
  end

  def slack_connection_status(%{connected: true} = assigns) do
    ~H"""
    <.slack_connected />
    """
  end

  def slack_connected(assigns) do
    ~H"""
    <div class="flex items-center space-x-1 pt-3">
      <%= img_tag("/images/Slack-mark-RGB.png", class: "w-4 h-4 toggle") %>
      <p>Slack Connected</p>
      <.icon name="check-circle" type="solid" class="text-green-600 h-5 w-5" />
    </div>
    """
  end

  attr :id, :string, default: nil
  slot :inner_block, required: true
  slot :heading
  slot :description

  def white_box_section(assigns) do
    ~H"""
    <div id={@id} class="white-box flex flex-col space-y-6">
      <div :if={@heading != []}>
        <.h3><%= render_slot(@heading) %></.h3>
        <p :if={@description != []} class="aside"><%= render_slot(@description) %></p>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def rounded_box(assigns) do
    ~H"""
    <div
      class={[
        "min-w-full shadow ring-1 ring-black ring-opacity-5 rounded-lg",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def fixed_sidebar(assigns) do
    ~H"""
    <div class="h-screen sticky top-0 flex flex-col space-y-4 w-64">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp language_icon_url("html" = name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}5/#{name}5-original.svg"
  end

  defp language_icon_url("objectivec" = name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}/#{name}-plain.svg"
  end

  defp language_icon_url("shell") do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/bash/bash-original.svg"
  end

  defp language_icon_url(name) do
    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{name}/#{name}-original.svg"
  end
end
