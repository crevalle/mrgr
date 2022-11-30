defmodule Mrgr.Worker.PushLabel do
  use Oban.Worker, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"label_repository_id" => id}}) do
    lr = Mrgr.Label.find_association(id)

    Mrgr.Label.push_label_to_repo(lr.label, lr)

    :ok
  end

  def perform(%Oban.Job{args: %{"id" => id}}) do
    label = Mrgr.Label.find_with_label_repositories(id)

    Mrgr.Label.push_to_all_repos(label)

    :ok
  end
end
