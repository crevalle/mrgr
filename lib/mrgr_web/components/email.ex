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

  def external_link(assigns) do
    style = "color: #2C746E;"

    assigns =
      assigns
      |> assign(:style, style)

    ~H"""
    <a href={@href} style={@style}><%= render_slot(@inner_block) %></a>
    """
  end

  def pr_list(%{pull_requests: []} = assigns), do: ~H"<.none />"

  def pr_list(assigns) do
    ~H"""
    <ul>
      <li :for={pr <- @pull_requests}>
        [<%= pr.repository.name %>]
        <a href={Mrgr.Schema.PullRequest.external_url(pr)}><%= pr.title %></a>
        (<%= author_handle(pr) %>) <.line_diff additions={pr.additions} deletions={pr.deletions} />
        <.hif_list hifs={pr.high_impact_file_rules} />
      </li>
    </ul>
    """
  end

  def situation_list(%{pull_requests: []} = assigns), do: ~H"<.none />"

  def situation_list(assigns) do
    ~H"""
    <ul>
      <li :for={pr <- @pull_requests}>
        [<%= pr.repository.name %>]
        <a href={Mrgr.Schema.PullRequest.external_url(pr)}><%= pr.title %></a>
        (<%= author_handle(pr) %>) <.line_diff additions={pr.additions} deletions={pr.deletions} />
        <span><strong>controversial</strong></span>
      </li>
    </ul>
    """
  end

  def none(assigns) do
    ~H"""
    <span><em>none!</em></span>
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
        <.l href={~p"/notifications"}>Update your email preferences</.l>
      </p>
    </div>
    """
  end

  def last_activity(%{activity: {:opened_at, _ts}} = assigns), do: ~H"PR was opened."

  def last_activity(%{activity: {:commit, commit}} = assigns) do
    assigns = assign(assigns, :commit, commit)

    ~H"""
    Commit <%= @commit.abbreviated_sha %> by <%= author_handle(@commit) %> was pushed <%= ago(
      Mrgr.DateTime.happened_at(@commit)
    ) %>:
    <p>
      <em>
        <%= Mrgr.Schema.PullRequest.commit_message(@commit) %>
      </em>
    </p>
    """
  end

  def last_activity(%{activity: {:comment, comment}} = assigns) do
    assigns = assign(assigns, :comment, comment)

    ~H"""
    Comment by <%= author_handle(@comment) %> left <%= ago(Mrgr.DateTime.happened_at(@comment)) %>:
    <p>
      <em>
        <%= Mrgr.Schema.Comment.body(@comment) %>
      </em>
    </p>
    """
  end

  def last_activity(%{activity: {:review, review}} = assigns) do
    assigns = assign(assigns, :review, review)

    ~H"""
    <%= pr_review_state(@review) %> by <%= author_handle(@review) %> left <%= ago(
      Mrgr.DateTime.happened_at(@review)
    ) %>
    """
  end
end
