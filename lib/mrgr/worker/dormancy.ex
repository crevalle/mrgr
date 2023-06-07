defmodule Mrgr.Worker.Dormancy do
  use Oban.Worker, max_attempts: 3

  # TODO: run every hour

  @impl Oban.Worker
  def perform(_job) do
    # we need a user's timezone to determine what's "dormant"
    # so we can't just pull "all dormant prs" because dormancy is relative to
    # a specific user.
    #
    # just notify of the current installation because users are likely to have
    # only one installation and i don't want to think about pulling comms preferences
    # for multiple installations right now.
    Mrgr.User.all()
    |> Enum.map(fn user ->
      prs = Mrgr.PullRequest.freshly_dormant(user.current_installation_id, user.timezone)

      # the notify function notifies all consumers of event
      Enum.map(prs, &Mrgr.Notification.Dormant.notify_consumers/1)
    end)

    :ok
  end
end
