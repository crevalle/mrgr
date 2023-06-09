defmodule Mrgr.Slack.Message.Welcome do
  use Mrgr.Slack.Message

  def render(%{hif_prs: [], situational_prs: [], dormant_prs: []}) do
    hifs = generate_example_hifs()
    situations = generate_example_situations()

    %{
      text: "Welcome to Mrgr! 👋",
      blocks: [
        header("Hello 👋!  Welcome to Mrgr."),
        section(intro()),
        section(dummy_alert_welcome()),
        section(render_hifs(hifs)),
        section(render_situations(situations)),
        section(footer_for_alerts())
      ]
    }
  end

  def render(%{hif_prs: hifs, situational_prs: situations, dormant_prs: dormants}) do
    %{
      text: "Welcome to Mrgr! 👋",
      blocks: [
        header("Hello 👋!  Welcome to Mrgr."),
        section(intro()),
        section(alert_welcome()),
        section(render_hifs(hifs)),
        section(render_situations(situations)),
        section(render_dormants(dormants)),
        section(footer_for_alerts())
      ]
    }
  end

  def intro do
    """
    You've successfully installed our Slackbot! All your notifications will be sent via Slack. \
    You may also opt-in to email notifications on your #{profile_link()} page.
    """
  end

  def alert_welcome do
    """
    Here is a quick summary of your open alerts.  You may want to check these out!
    """
  end

  def dummy_alert_welcome do
    """
    The following are some *example alerts* to give you a taste of what’s coming.
    """
  end

  def render_dormants(prs) do
    "😴 *Dormant PRs*\n#{dormant_list(prs)}"
  end

  def render_situations(prs) do
    "🔍 *Situational Alerts*\n#{situation_list(prs)}"
  end

  def dormant_list([]) do
    "_none!_"
  end

  def dormant_list(prs) do
    # max block length is 3000 chars, so arbitrarily cut these off
    # to avoid hitting that.
    prs
    |> Enum.take(3)
    |> Mrgr.Slack.Message.Dormant.render_pull_requests()
  end

  def situation_list([]) do
    "_none!_"
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

  def generate_example_hifs do
    [
      %Mrgr.Schema.PullRequest{
        title: "_Example Pull Request 1_",
        author: %{login: "Captain_Kirk"},
        high_impact_file_rules: [
          %Mrgr.Schema.HighImpactFileRule{
            name: "migration"
          }
        ]
      },
      %Mrgr.Schema.PullRequest{
        title: "_Example Pull Request 2_",
        author: %{login: "Mr_Spock"},
        high_impact_file_rules: [
          %Mrgr.Schema.HighImpactFileRule{
            name: "dependencies"
          }
        ]
      }
    ]
  end

  def generate_example_situations do
    # right now, hard codes to controversial PRs
    [
      %Mrgr.Schema.PullRequest{
        title: "_Example Pull Request 3_",
        author: %{login: "Dr_McCoy"}
      }
    ]
  end

  defp profile_link do
    url = "#{MrgrWeb.Endpoint.url()}#{~p"/profile"}"

    build_link(url, "profile")
  end
end
