defmodule Mrgr.Worker.StripeWebhook do
  use Oban.Worker, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    webhook = Mrgr.Stripe.Webhook.get(id)

    Mrgr.Stripe.Webhook.fire!(webhook)

    :ok
  end
end
