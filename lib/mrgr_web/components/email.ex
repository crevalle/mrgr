defmodule MrgrWeb.Components.Email do
  @green_600 "#4aa35b"
  @red_400 "#ed7a74"

  use MrgrWeb, :component
  use Phoenix.VerifiedRoutes, endpoint: MrgrWeb.Endpoint, router: MrgrWeb.Router

  def l(assigns) do
    url = Phoenix.VerifiedRoutes.unverified_url(MrgrWeb.Endpoint, assigns.href)
    style = "color: #2C746E;"

    assigns =
      assigns
      |> assign(:url, url)
      |> assign(:style, style)

    ~H"""
    <a href={@url} style={@style}><%= render_slot(@inner_block) %></a>
    """
  end

  def pr_list(assigns) do
    ~H"""
    <%= if @pull_requests == [] do %>
      <span><em>none!</em></span>
    <% else %>
      <ul>
        <li :for={pr <- @pull_requests}>
          [<%= pr.repository.name %>]
          <a href={Mrgr.Schema.PullRequest.external_url(pr)}><%= pr.title %></a>
          (<%= Mrgr.Schema.PullRequest.author_name(pr) %>)
          <.line_diff additions={pr.additions} deletions={pr.deletions} />
          <.hif_list hifs={pr.high_impact_file_rules} />
        </li>
      </ul>
    <% end %>
    """
  end

  def line_diff(assigns) do
    assigns =
      assigns
      |> assign(:green_text, "color: #{@green_600};")
      |> assign(:red_text, "color: #{@red_400};")

    ~H"""
    <span style={"#{@green_text} padding-left: 0.25rem;"}>
      +<%= number_with_delimiter(@additions) %>
    </span>
    <span style={@red_text}>-<%= number_with_delimiter(@deletions) %></span>
    """
  end

  def daily_changelog(assigns) do
    ~H"""
    <h3><%= Calendar.strftime(@day.date, "%A %-m/%-d") %></h3>
    <.pr_list pull_requests={@day.pull_requests} />
    """
  end

  def hif_list(%{hifs: []} = assigns), do: ~H[]

  def hif_list(assigns) do
    ~H"""
    <br />
    <.hif_badge :for={hif <- @hifs} hif={hif} />
    """
  end

  def hif_badge(assigns) do
    styles =
      [
        "background-color: #{assigns.hif.color}",
        "line-height: 1.25rem",
        "font-weight: 600",
        "font-size: 0.75rem",
        "line-height: 1rem",
        "padding-left: 0.5rem",
        "padding-right: 0.5rem",
        "border-radius: 9999px"
      ]
      |> Enum.join(";")

    assigns = assign(assigns, :styles, styles)

    ~H"""
    <span style={@styles}><%= @hif.name %></span>
    """
  end

  def up_or_down(%{this_week: this, last_week: last} = assigns) do
    yep =
      cond do
        this < last ->
          "down"

        this > last ->
          "up"

        this == last ->
          "the same"

        true ->
          "a good question"
      end

    assigns = assign(assigns, :yep, yep)

    ~H"""
    <strong><%= @yep %></strong>
    """
  end

  def update_email_preferences_link(assigns) do
    ~H"""
    <div style="padding-top: 2rem;">
      <p style="font-weight: 400; font-size: 0.75rem; line-height: 1rem;">
        <.l href={~p"/profile"}>Update your email preferences</.l>
      </p>
    </div>
    """
  end
end
