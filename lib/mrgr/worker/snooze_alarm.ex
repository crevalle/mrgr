defmodule Mrgr.Worker.SnoozeAlarm do
  use Oban.Worker, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Mrgr.PullRequest.Snoozer.expire_past_due_snoozes()

    :ok
  end
end
