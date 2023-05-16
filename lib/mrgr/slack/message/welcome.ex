defmodule Mrgr.Slack.Message.Welcome do
  use Mrgr.Slack.Message

  def render(%{hif_prs: [], situational_prs: []}) do
    # nothin'
  end

  def render(%{hif_prs: hifs, situational_prs: situations}) do
    %{
      text: "Welcome to Mrgr! 👋",
      blocks: [
        header("Hello 👋!  Welcome to Mrgr."),
        section(alert_welcome()),
        section(render_hifs(hifs)),
        section(render_situations(situations)),
        section(footer_for_alerts())
      ]
    }
  end

  def alert_welcome do
    """
    You've successfully installed our Slackbot! All your notifications will be sent via Slack. \
    You may also opt-in to email notifications on your #{profile_link()} page.

    Here is a quick summary of your open alerts.  You may want to check these out!
    """
  end

  def render_situations(prs) do
    "🔎 *Situational Alerts*\n#{situation_list(prs)}"
  end

  def situation_list(prs) do
    Enum.map(prs, fn pr ->
      "• [controversial] - #{build_link(github_url(pr), pr.title)} by #{author_handle(pr)}"
    end)
    |> Enum.join("\n")
  end

  def render_hifs(prs) do
    "💥 *High Impact Files*\n#{hif_list(prs)}"
  end

  def hif_list([]) do
    "_none!_"
  end

  def hif_list(prs) do
    prs
    |> Enum.map(&render_hif/1)
    |> Enum.join("\n")
  end

  def render_hif(pr) do
    badges = badge_list(pr.high_impact_file_rules)

    "• #{badges} - #{build_link(github_url(pr), pr.title)} by #{author_handle(pr)}"
  end

  def badge_list(rules) do
    Enum.map(rules, fn rule ->
      "[#{rule.name}]"
    end)
    |> Enum.join(" ")
  end

  def footer_for_alerts do
    """
    Going forward, we’ll send you a notice for *_each alert that happens_*. \
    This consolidated summary is just a welcome note 🙂.

    Be sure to add new alerts or update your notification settings \
    on your #{profile_link()} page. Happy merging!
    """
  end

  def footer_for_no_alerts do
    "These are just examples to give you a taste of what’s coming.  Going forward, we’ll send you a notice for each alert that happens.  This summary is just a welcome note 🙂.  Be sure to add new alerts or update your notification settings on your #{profile_link()} page.  Thanks!"
  end

  defp profile_link do
    url = "#{MrgrWeb.Endpoint.url()}#{~p"/profile"}"

    build_link(url, "profile")
  end

  defp github_url(pr) do
    Mrgr.Schema.PullRequest.external_url(pr)
  end
end
