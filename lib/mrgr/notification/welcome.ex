defmodule Mrgr.Notification.Welcome do
  def send_via_slack(user) do
    prs = %{
      hif_prs: Mrgr.PullRequest.hif_prs_for_user(user),
      situational_prs: Mrgr.PullRequest.situational_for_user(user)
    }

    message = Mrgr.Slack.Message.Welcome.render(prs)

    # recipient first?
    Mrgr.Slack.send_message(message, user)
  end
end
