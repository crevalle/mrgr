defmodule Mrgr.Worker.InstallationOnboarding do
  @sync_closed_prs "sync_closed_prs"

  use Oban.Worker,
    # don't retry failed jobs
    max_attempts: 1,
    # don't enqueue another job for this installation if another
    # one is scheduled or running
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  def perform(%Oban.Job{args: %{"job" => @sync_closed_prs, "id" => id}}) do
    installation = Mrgr.Installation.find_for_onboarding(id)

    Mrgr.Installation.sync_closed_pull_requests(installation)

    :ok
  end

  def perform(%Oban.Job{args: %{"id" => id}}) do
    installation = Mrgr.Installation.find_for_onboarding(id)

    Mrgr.Installation.onboard(installation)

    :ok
  end

  def queue_sync_closed_prs(installation) do
    %{id: installation.id, job: @sync_closed_prs}
    |> Mrgr.Worker.InstallationOnboarding.new()
    |> Oban.insert()
  end
end
