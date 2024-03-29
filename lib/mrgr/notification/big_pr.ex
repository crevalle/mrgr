defmodule Mrgr.Notification.BigPR do
  use Mrgr.Notification.Event
  import Mrgr.Tuple

  @spec send_alert(Mrgr.Schema.PullRequest.t()) ::
          {:ok, map()} | {:error, :already_notified} | {:error, :not_big}
  def send_alert(pull_request) do
    # !!! This does not really respect different users' preferences, nor does it
    # account for "has _this specific user_ been notified".  Instead we say "was anyone notified"
    # and "is it big enough for the account's creator."  TBD.
    with :ok <- Mrgr.Notification.ensure_freshness(pull_request.notifications, @big_pr),
         :ok <- big_enough(pull_request) do
      pull_request
      |> notify_consumers()
      |> ok()
    end
  end

  def big_enough(pull_request) do
    %{settings: %{big_pr_threshold: threshold}} =
      Mrgr.Notification.load_creator_preference(pull_request, @big_pr)

    with false <- over_threshold?(pull_request.additions, threshold),
         false <- over_threshold?(pull_request.deletions, threshold) do
      {:error, :not_big}
    else
      true ->
        :ok
    end
  end

  def over_threshold?(num, threshold) when num > threshold, do: true
  def over_threshold?(_num, _threshold), do: false

  def notify_consumers(pull_request) do
    pull_request = Mrgr.Repo.preload(pull_request, [:author, :repository])

    consumers = fetch_consumers(pull_request)

    email =
      Enum.map(consumers.email, fn recipient ->
        send_email(recipient, pull_request)
      end)

    slack =
      Enum.map(consumers.slack, fn recipient ->
        send_slack(recipient, pull_request)
      end)

    %{email: email, slack: slack}
  end

  def fetch_consumers(pull_request) do
    Mrgr.Notification.consumers_of_event(@big_pr, pull_request)
  end

  def send_email(recipient, pull_request) do
    email = Mrgr.Email.big_pr(recipient, pull_request)

    Mrgr.Mailer.deliver_and_log(email, @big_pr, pull_request)
  end

  def send_slack(recipient, pull_request) do
    message = Mrgr.Slack.Message.BigPR.render(pull_request)

    Mrgr.Slack.send_and_log(message, recipient, @big_pr, pull_request)
  end
end
