defmodule Mrgr.Worker.Dormancy do
  use Oban.Worker, max_attempts: 3

  # TODO: run every hour

  @impl Oban.Worker
  def perform(_job) do
    # what about many users at an installation?
    #
    # tempted to ignore that completely.
    Mrgr.Installation.all()
    |> Enum.map(fn i ->
      creator = Mrgr.User.find(i.creator_id)

      # users with many installations is awkward enough

      prs =
        Mrgr.PullRequest.freshly_dormant(i.id, creator.timezone)
        |> IO.inspect(label: i.id)

      # fix this: either loop through installations or loop through users.
      # the notify function notifies all consumers of event
      Mrgr.Notification.Dormant.notify_user_of_dormant_prs(i.id, prs)
    end)

    :ok
  end
end
