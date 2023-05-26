defmodule Mrgr.Worker.DormantAlarm do
  use Oban.Worker, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # que user?
    # we compute dormancy in memory, so how do we batch these? or at least segment them?
    # Mrgr.PullRequest.freshly_dormant()
    # |> Enum.map(&Mrgr.PullRequest.Controversy.notify(&1, user))

    :ok
  end
end
