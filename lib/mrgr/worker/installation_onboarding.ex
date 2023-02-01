defmodule Mrgr.Worker.InstallationOnboarding do
  @sync_closed_prs "sync_closed_prs"

  use Oban.Worker, max_attempts: 3

  def perform(%Oban.Job{args: %{"job" => @sync_closed_prs, "id" => id}}) do
    installation = Mrgr.Installation.find_for_onboarding(id)

    Mrgr.Installation.sync_closed_pull_requests(installation)

    :ok
  end

  def perform(%Oban.Job{args: %{"id" => id}}) do
    installation = Mrgr.Installation.find_for_onboarding(id)

    Mrgr.Installation.sync_data_for_onboarding(installation)

    :ok
  end

  def queue_sync_closed_prs(installation) do
    %{id: installation.id, job: @sync_closed_prs}
    |> Mrgr.Worker.InstallationOnboarding.new()
    |> Oban.insert()
  end
end
