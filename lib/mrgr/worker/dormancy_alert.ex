defmodule Mrgr.Worker.DormancyAlert do
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
      case send_alarm?(user.timezone) do
        true ->
          prs = Mrgr.PullRequest.freshly_dormant(user.current_installation_id, user.timezone)

          Mrgr.Notification.Dormant.notify_consumers(prs, user.current_installation_id)

        false ->
          # no-op
          nil
      end
    end)

    :ok
  end

  # don't run alarmer on weekends.  the dormancy freshness logic assumes that saturday and sunday don't
  # exist.
  def send_alarm?(timezone) do
    timezone
    |> DateTime.now!()
    |> Date.day_of_week()
    |> weekday?()
  end

  def weekday?(day) when day in [1, 2, 3, 4, 5], do: true
  def weekday?(day) when day in [6, 7], do: false
end
