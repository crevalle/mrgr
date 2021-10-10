defmodule Mrgr.Merge do
  def create(payload) do
    repository_id = payload["repository"]["id"]
    repo = Mrgr.Github.find(Mrgr.Schema.Repository, repository_id)

    user_id = payload["pull_request"]["user"]["id"]
    author = Mrgr.Github.find(Mrgr.Schema.Member, user_id)

    params =
      payload
      |> Map.get("pull_request")
      |> Map.put("repository_id", repo.id)
      |> Map.put("author_id", author.id)
      |> Map.put("opened_at", payload["pull_request"]["created_at"])


    params
    |> Mrgr.Schema.Merge.create_changeset()
    |> Mrgr.Repo.insert()
  end
end
