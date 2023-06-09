defmodule Mrgr.Notification.Welcome do
  @name "welcome"

  def send_via_slack(user) do
    prs = %{
      hif_prs: Mrgr.PullRequest.hif_prs_for_user(user),
      dormant_prs: Mrgr.PullRequest.open_prs(user),
      situational_prs: Mrgr.PullRequest.situational_for_user(user)
    }

    message = Mrgr.Slack.Message.Welcome.render(prs)

    Mrgr.Slack.send_and_log(message, user, @name)
  end

  def send_via_email(user) do
    prs = %{
      hif_prs: Mrgr.PullRequest.hif_prs_for_user(user),
      situational_prs: Mrgr.PullRequest.situational_for_user(user)
    }

    email = Mrgr.Email.welcome(user, prs)

    Mrgr.Mailer.deliver_and_log(email, @name)
  end
end
