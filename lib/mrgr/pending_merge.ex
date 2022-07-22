defmodule Mrgr.PendingMerge do
  def create_first_linky_comment(repo, pr, token) do
    # crevalle/mrgr => ["crevalle", "mrgr"]
    [owner, repo_name] = String.split(repo.full_name, "/")

    comment = %{body: "hi desmond!"}

    client = Tentacat.Client.new(%{access_token: token})
    Tentacat.Issues.Comments.create(client, owner, repo_name, pr.number, comment)
  end
end
