defmodule Mrgr.Worker.GithubWebhook do
  use Oban.Worker, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    webhook = Mrgr.IncomingWebhook.get(id)

    Mrgr.IncomingWebhook.fire!(webhook)

    :ok
  end
end
