defmodule Mrgr.Mailer do
  use Swoosh.Mailer, otp_app: :mrgr

  def deliver_and_log(email, type, pull_request \\ []) do
    res = deliver(email)

    recipient_id = email.private.user_id

    Mrgr.Notification.create(recipient_id, res, "email", type, pull_request)

    res
  end
end
