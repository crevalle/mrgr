defmodule MrgrWeb.Components.UI do
  use MrgrWeb, :component

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
      <p class="mt-1 mb-2" >
        <%= render_slot(@description) %>
      </p>
    <% end %>
    """
  end

  def button(assigns) do
    colors =
      if assigns[:disabled] do
        "bg-gray-600 hover:bg-gray-700 focus:ring-gray-500"
      else
        assigns[:colors]
      end

    class =
      "inline-flex items-center py-2 px-4 border border-transparent shadow-md text-sm font-medium rounded-md text-white focus:outline-none focus:ring-2 focus:ring-offset-2 #{colors}"

    type = if assigns[:submit], do: "submit", else: false

    extra = assigns_to_attributes(assigns, [:submit])

    assigns =
      assigns
      |> assign(:type, type)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
      <button type={@type} class={@class} {@extra} >
        <%= render_slot(@inner_block) %>
      </button>
    """
  end

  def secondary_button(assigns) do
    colors =
      if assigns[:disabled] do
        "text-gray-700 border-gray-700 hover:bg-gray-700"
      else
        assigns[:colors]
      end

    standard_opts =
      Enum.join(
        [
          "inline-flex",
          "items-center",
          "py-2",
          "px-4",
          "shadow-md",
          "text-sm",
          "font-medium",
          "border",
          "hover:border-transparent",
          "hover:text-white",
          "rounded-md",
          "bg-transparent"
        ],
        " "
      )

    class = "#{standard_opts} #{colors}"

    type = if assigns[:submit], do: "submit", else: false

    extra = assigns_to_attributes(assigns, [:submit])

    assigns =
      assigns
      |> assign(:type, type)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
      <button type={@type} class={@class} {@extra} >
        <%= render_slot(@inner_block) %>
      </button>
    """
  end

  def copy_button(assigns) do
    ~H"""
    <.button colors="bg-blue-600 hover:bg-blue-700 focus:ring-blue-500"
              phx-click={Phoenix.LiveView.JS.dispatch("mrgr:clipcopy", to: @target)}>
      Copy to Clipboard
    </.button>
    """
  end

  def heading(assigns) do
    assigns = assign_new(assigns, :description, fn -> nil end)

    ~H"""
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <.h1><%= @title %></.h1>
        <%= if @description do %>
          <p class="mt-2 text-sm text-gray-700"><%= @description %></p>
        <% end %>
      </div>
    </div>
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

    class = "border-t border-gray-300 py-4 #{striped}"

    assigns = assign(assigns, :class, class)

    ~H"""
    <tr class={@class}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  def td(assigns) do
    class = "whitespace-nowrap px-3 py-4 text-gray-700 #{assigns[:class]}"

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
        <.table_attr obj={@installation} key={:app_id} ./>
        <.table_attr obj={@installation} key={:app_slug} ./>
        <.table_attr obj={@installation} key={:events} ./>
        <.table_attr obj={@installation} key={:external_id} ./>
        <.table_attr obj={@installation} key={:html_url} ./>
        <.table_attr obj={@installation} key={:installation_created_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:permissions} ./>
        <.table_attr obj={@installation} key={:repositories_url} ./>
        <.table_attr obj={@installation} key={:repository_selection} ./>
        <.table_attr obj={@installation} key={:target_id} ./>
        <.table_attr obj={@installation} key={:target_type} ./>
        <.table_attr obj={@installation} key={:access_tokens_url} ./>
        <.table_attr obj={@installation} key={:token} tz={@tz} ./>
        <.table_attr obj={@installation} key={:token_expires_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:updated_at} tz={@tz} ./>
        <.table_attr obj={@installation} key={:inserted_at} tz={@tz} ./>
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
            <.td><%= link user.id, to: Routes.admin_user_path(MrgrWeb.Endpoint, :show, user.id), class: "text-teal-700 hover:text-teal-500" %></.td>
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

  def admin_repository_table(assigns) do
    ~H"""
      <table class="min-w-full">
        <thead class="bg-white">
          <tr>
            <.th uppercase={true}>ID</.th>
            <.th uppercase={true}>External ID</.th>
            <.th uppercase={true}>Full Name</.th>
            <.th uppercase={true}>Private?</.th>
            <.th uppercase={true}>Merge Freeze Enabled?</.th>
            <.th uppercase={true}>Updated</.th>
            <.th uppercase={true}>Created</.th>
          </tr>
        </thead>

        <%= for repo <- @repositories do %>
          <.tr striped={true}>
            <.td><%= repo.id %></.td>
            <.td><%= repo.external_id %></.td>
            <.td><%= repo.full_name %></.td>
            <.td><%= repo.private %></.td>
            <.td><%= repo.merge_freeze_enabled %></.td>
            <.td><%= ts(repo.updated_at, @tz) %></.td>
            <.td><%= ts(repo.inserted_at, @tz) %></.td>
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
    ~H()
  end

  def language_icon(assigns) do
    name =
      assigns.language
      |> String.downcase()
      |> String.replace("-", "")

    src = language_icon_url(name)

    assigns = assign(assigns, :src, src)

    ~H"""
      <img src={@src} class="ml-1 h-5 w-5"/>
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
