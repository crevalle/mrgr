defmodule Mrgr.Worker.WeeklyPRSummary do
  use Oban.Worker, max_attempts: 1

  @week_from_now_in_seconds 7 * 86400

  @impl Oban.Worker
  # job for each user
  def perform(%Oban.Job{args: %{"user_id" => id}}) do
    user = Mrgr.User.find_with_current_installation(id)

    Mrgr.User.send_pr_summary(user)

    :ok
  end

  # weekly job that enqueues a job for each user
  def perform(%Oban.Job{args: %{"job" => "weekly"}}) do
    schedule_next_job()

    users = Mrgr.User.wanting_pr_summary()

    Enum.each(users, &enqueue_job_for_user/1)

    :ok
  end

  def enqueue_job_for_user(user) do
    %{"user_id" => user.id}
    |> Mrgr.Worker.WeeklyPRSummary.new()
    |> Oban.insert()
  end

  # will drift a bit, oh well
  # Oban doesn't support scheduling in ms
  def schedule_next_job(schedule_in \\ @week_from_now_in_seconds) do
    %{"job" => "weekly"}
    |> Mrgr.Worker.WeeklyPRSummary.new(schedule_in: schedule_in)
    |> Oban.insert()
  end
end
