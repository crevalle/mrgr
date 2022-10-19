defmodule Mrgr.Installation.Facilitator do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    installation = Mrgr.Installation.find_for_setup(id)

    Mrgr.Installation.complete_setup(installation)

    :ok
  end
end
