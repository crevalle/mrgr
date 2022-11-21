defmodule Mrgr.Worker.EnforceRepositorySettings do
  use Oban.Worker, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"policy_id" => id, "repo_id" => repo_id}}) do
    policy = Mrgr.RepositorySettingsPolicy.find(id)
    # see below.  need this for broadcasting to the live view
    repository = %{Mrgr.Repository.find(repo_id) | policy: policy}

    Mrgr.Repository.enforce_repo_policy(repository, policy)

    :ok
  end

  def perform(%Oban.Job{args: %{"policy_id" => id}}) do
    policy = Mrgr.RepositorySettingsPolicy.find_with_repos(id)

    # currently doing all API calls one at a time.  Later we can
    # get smarter about this but i don't want to risk overloading the
    # connection pool
    Enum.map(policy.repositories, fn repo ->
      # ends up getting broadcast to the RepoListLiveView which
      # expects policy to be preloaded
      repo = %{repo | policy: policy}

      Mrgr.Repository.enforce_repo_policy(repo, policy)
    end)

    :ok
  end
end
