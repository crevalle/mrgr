defmodule Mrgr.Worker.DeleteLabel do
  use Oban.Worker, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"label_repository_id" => id}}) do
    lr = Mrgr.Label.find_association(id)

    Mrgr.Label.delete_repo_association(lr)

    :ok
  end

  def perform(%Oban.Job{args: %{"id" => id}}) do
    label = Mrgr.Label.find_with_label_repositories(id)

    Mrgr.Label.delete(label)

    :ok
  end
end
