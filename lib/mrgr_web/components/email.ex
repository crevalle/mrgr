defmodule MrgrWeb.Components.Email do
  use MrgrWeb, :component

  def pr_list(assigns) do
    ~H"""
    <%= if @pull_requests == [] do %>
      <span><em>none!</em></span>
    <% else %>
      <ul>
        <li :for={pr <- @pull_requests}>
          <a href={Mrgr.Schema.PullRequest.external_pull_request_url(pr)}><%= pr.title %></a>
          [<%= Mrgr.Schema.PullRequest.author_name(pr) %>]
          <.hif_list hifs={pr.high_impact_file_rules} />
        </li>
      </ul>
    <% end %>
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
    <span style={@styles}>
      <%= @hif.name %>
    </span>
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
end
