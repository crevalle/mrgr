defmodule Mrgr.Mailer do
  use Swoosh.Mailer, otp_app: :mrgr

  def deliver_and_log(email, type) do
    res = deliver(email)

    recipient_id = email.private.user_id

    Mrgr.Notification.create(recipient_id, res, "email", type)

    res
  end
end
