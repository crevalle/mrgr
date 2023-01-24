defmodule Mrgr.Worker.InstallationOnboarding do
  use Oban.Worker, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    installation = Mrgr.Installation.find_for_onboarding(id)

    Mrgr.Installation.sync_data_for_onboarding(installation)

    :ok
  end
end
