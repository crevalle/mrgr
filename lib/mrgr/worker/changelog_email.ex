defmodule Mrgr.Worker.ChangelogEmail do
  use Oban.Worker, max_attempts: 1

  @impl Oban.Worker
  # job for each user
  def perform(%Oban.Job{args: %{"user_id" => id}}) do
    user = Mrgr.User.find_with_current_installation(id)

    Mrgr.User.send_changelog(user)

    :ok
  end

  # weekly job that enqueues a job for each user
  def perform(%Oban.Job{args: %{"job" => "weekly"}}) do
    users = Mrgr.User.wanting_changelog()

    Enum.each(users, &enqueue_job_for_user/1)

    :ok
  end

  def enqueue_job_for_user(user) do
    %{"user_id" => user.id}
    |> Mrgr.Worker.ChangelogEmail.new()
    |> Oban.insert()
  end
end
