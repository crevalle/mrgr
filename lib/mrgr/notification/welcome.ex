defmodule Mrgr.Notification.Welcome do
  @name "welcome"

  def send_via_slack(user) do
    hif_prs = Mrgr.PullRequest.hif_prs_for_user(user)
    dormant_prs = Mrgr.PullRequest.dormant_prs(user)
    situational_prs = Mrgr.PullRequest.situational_for_user(user)

    prs = %{
      hif_prs: hif_prs,
      dormant_prs: dormant_prs,
      situational_prs: situational_prs
    }

    message = Mrgr.Slack.Message.Welcome.render(prs)

    # all but last one get duplicated, so i think this is fastest
    pr_list = hif_prs ++ situational_prs ++ dormant_prs
    Mrgr.Slack.send_and_log(message, user, @name, pr_list)
  end

  def send_via_email(user) do
    hif_prs = Mrgr.PullRequest.hif_prs_for_user(user)
    situational_prs = Mrgr.PullRequest.situational_for_user(user)

    prs = %{
      hif_prs: hif_prs,
      situational_prs: situational_prs
    }

    email = Mrgr.Email.welcome(user, prs)

    pr_list = hif_prs ++ situational_prs
    Mrgr.Mailer.deliver_and_log(email, @name, pr_list)
  end
end
