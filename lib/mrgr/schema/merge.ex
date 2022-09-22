defmodule Mrgr.Schema.Merge do
  use Mrgr.Schema

  schema "merges" do
    field(:external_id, :integer)
    field(:number, :integer)
    field(:opened_at, :utc_datetime)
    field(:status, :string)
    field(:title, :string)
    field(:url, :string)
    field(:merge_queue_index, :integer)
    field(:files_changed, {:array, :string})
    field(:head_commit, :map)
    field(:raw, :map)

    embeds_many(:commits, Mrgr.Github.Commit, on_replace: :delete)

    embeds_many(:assignees, Mrgr.Github.User, on_replace: :delete)
    embeds_many(:requested_reviewers, Mrgr.Github.User, on_replace: :delete)

    embeds_one(:user, Mrgr.Github.User, on_replace: :update)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    embeds_one(:merged_by, Mrgr.Github.User, on_replace: :update)
    field(:merged_at, :utc_datetime)

    timestamps()
  end

  @create_fields ~w[
    number
    opened_at
    title
    url
    repository_id
    merge_queue_index
    raw
  ]a

  @synchronize_fields ~w[
    title
  ]a

  def create_changeset(schema, params) do
    params = set_opened_at(params)

    schema
    |> cast(params, @create_fields)
    |> cast_embed(:user)
    |> cast_embed(:head)
    |> put_open_status()
    |> put_external_id()
    |> put_change(:raw, params)
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def commits_changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:commits)
  end

  def merge_queue_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:merge_queue_index])
  end

  def synchronize_changeset(schema, %{"pull_request" => params}) do
    schema
    |> cast(params, @synchronize_fields)
    |> cast_embed(:head)
    |> put_change(:raw, params)
  end

  def close_changeset(schema, %{"merged" => true} = params) do
    schema
    |> cast(params, [])
    |> cast_embed(:merged_by)
    |> put_closed_status()
    |> put_timestamp(:merged_at)
  end

  def close_changeset(schema, %{"merged" => false} = params) do
    schema
    |> cast(params, [])
    |> put_closed_status()
  end

  def put_closed_status(changeset) do
    put_change(changeset, :status, "closed")
  end

  def put_open_status(changeset) do
    case get_change(changeset, :status) do
      empty when empty in [nil, ""] ->
        put_change(changeset, :status, "open")

      _status ->
        changeset
    end
  end

  def set_opened_at(%{:created_at => at} = params) do
    Map.put(params, :opened_at, at)
  end

  def set_opened_at(%{"created_at" => at} = params) do
    Map.put(params, "opened_at", at)
  end

  def external_merge_url(%{raw: %{"_links" => %{"html" => %{"href" => url}}}}), do: url
  def external_merge_url(_merge), do: ""

  def head_commit_message(%{head_commit: %{"commit" => %{"message" => message}}}), do: message
  def head_commit_message(_), do: "-"

  def head_committer(%{head_commit: %{"commit" => %{"committer" => %{"name" => name}}}}), do: name
  def head_committer(_), do: "-"

  def head_committed_at(%{head_commit: %{"commit" => %{"committer" => %{"date" => date}}}}) do
    {:ok, dt, _huh} = DateTime.from_iso8601(date)
    dt
  end

  def head_committed_at(_), do: nil

  def commit_message(%Mrgr.Github.Commit{commit: commit}) do
    commit.message
  end

  def author_name(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.name
  end

  def committed_at(%Mrgr.Github.Commit{commit: commit}) do
    commit.author.date
  end

  def commit_sha(%Mrgr.Github.Commit{} = commit) do
    commit.sha
  end

  ### HEAD_COMMIT
  #  %{
  #    "author" => %{
  #      "avatar_url" => "https://avatars.githubusercontent.com/u/572921?v=4",
  #      "events_url" => "https://api.github.com/users/desmondmonster/events{/privacy}",
  #      "followers_url" => "https://api.github.com/users/desmondmonster/followers",
  #      "following_url" => "https://api.github.com/users/desmondmonster/following{/other_user}",
  #      "gists_url" => "https://api.github.com/users/desmondmonster/gists{/gist_id}",
  #      "gravatar_id" => "",
  #      "html_url" => "https://github.com/desmondmonster",
  #      "id" => 572921,
  #      "login" => "desmondmonster",
  #      "node_id" => "MDQ6VXNlcjU3MjkyMQ==",
  #      "organizations_url" => "https://api.github.com/users/desmondmonster/orgs",
  #      "received_events_url" => "https://api.github.com/users/desmondmonster/received_events",
  #      "repos_url" => "https://api.github.com/users/desmondmonster/repos",
  #      "site_admin" => false,
  #      "starred_url" => "https://api.github.com/users/desmondmonster/starred{/owner}{/repo}",
  #      "subscriptions_url" => "https://api.github.com/users/desmondmonster/subscriptions",
  #      "type" => "User",
  #      "url" => "https://api.github.com/users/desmondmonster"
  #    },
  #    "comments_url" => "https://api.github.com/repos/crevalle/mrgr/commits/5ffdd99905664ba68a33b984ec9f58b57fe8d126/comments",
  #    "commit" => %{
  #      "author" => %{
  #        "date" => "2022-07-06T01:12:36Z",
  #        "email" => "desmond@crevalle.io",
  #        "name" => "Desmond Bowe"
  #      },
  #      "comment_count" => 0,
  #      "committer" => %{
  #        "date" => "2022-07-06T01:12:36Z",
  #        "email" => "desmond@crevalle.io",
  #        "name" => "Desmond Bowe"
  #      },
  #      "message" => "the actual name",
  #      "tree" => %{
  #        "sha" => "1bff6060e30d706ffff42c956b15c32d029ce473",
  #        "url" => "https://api.github.com/repos/crevalle/mrgr/git/trees/1bff6060e30d706ffff42c956b15c32d029ce473"
  #      },
  #      "url" => "https://api.github.com/repos/crevalle/mrgr/git/commits/5ffdd99905664ba68a33b984ec9f58b57fe8d126",
  #      "verification" => %{
  #        "payload" => nil,
  #        "reason" => "unsigned",
  #        "signature" => nil,
  #        "verified" => false
  #      }
  #    },
  #    "committer" => %{
  #      "avatar_url" => "https://avatars.githubusercontent.com/u/572921?v=4",
  #      "events_url" => "https://api.github.com/users/desmondmonster/events{/privacy}",
  #      "followers_url" => "https://api.github.com/users/desmondmonster/followers",
  #      "following_url" => "https://api.github.com/users/desmondmonster/following{/other_user}",
  #      "gists_url" => "https://api.github.com/users/desmondmonster/gists{/gist_id}",
  #      "gravatar_id" => "",
  #      "html_url" => "https://github.com/desmondmonster",
  #      "id" => 572921,
  #      "login" => "desmondmonster",
  #      "node_id" => "MDQ6VXNlcjU3MjkyMQ==",
  #      "organizations_url" => "https://api.github.com/users/desmondmonster/orgs",
  #      "received_events_url" => "https://api.github.com/users/desmondmonster/received_events",
  #      "repos_url" => "https://api.github.com/users/desmondmonster/repos",
  #      "site_admin" => false,
  #      "starred_url" => "https://api.github.com/users/desmondmonster/starred{/owner}{/repo}",
  #      "subscriptions_url" => "https://api.github.com/users/desmondmonster/subscriptions",
  #      "type" => "User",
  #      "url" => "https://api.github.com/users/desmondmonster"
  #    },
  #    "files" => [
  #      %{
  #        "additions" => 1,
  #        "blob_url" => "https://github.com/crevalle/mrgr/blob/5ffdd99905664ba68a33b984ec9f58b57fe8d126/lib%2Fmrgr_web%2Flive%2Fpending_merge_live.ex",
  #        "changes" => 2,
  #        "contents_url" => "https://api.github.com/repos/crevalle/mrgr/contents/lib%2Fmrgr_web%2Flive%2Fpending_merge_live.ex?ref=5ffdd99905664ba68a33b984ec9f58b57fe8d126",
  #        "deletions" => 1,
  #        "filename" => "lib/mrgr_web/live/pending_merge_live.ex",
  #        "patch" => "@@ -185,7 +185,7 @@ defmodule MrgrWeb.PendingMergeLive do\n \n   def has_migration?(%{files_changed: files}) do\n     Enum.any?(files, fn f ->\n-      String.starts_with?(f, \"priv\")\n+      String.starts_with?(f, \"priv/repo/migrations\")\n     end)\n   end\n end",
  #        "raw_url" => "https://github.com/crevalle/mrgr/raw/5ffdd99905664ba68a33b984ec9f58b57fe8d126/lib%2Fmrgr_web%2Flive%2Fpending_merge_live.ex",
  #        "sha" => "acbf69f1c03d61d34032fdc539421de362f1ee42",
  #        "status" => "modified"
  #      }
  #    ],
  #    "html_url" => "https://github.com/crevalle/mrgr/commit/5ffdd99905664ba68a33b984ec9f58b57fe8d126",
  #    "node_id" => "C_kwDOGGc3xdoAKDVmZmRkOTk5MDU2NjRiYTY4YTMzYjk4NGVjOWY1OGI1N2ZlOGQxMjY",
  #    "parents" => [
  #      %{
  #        "html_url" => "https://github.com/crevalle/mrgr/commit/3fef6c68cc71e774e7752edcd169bd2d1e46fd57",
  #        "sha" => "3fef6c68cc71e774e7752edcd169bd2d1e46fd57",
  #        "url" => "https://api.github.com/repos/crevalle/mrgr/commits/3fef6c68cc71e774e7752edcd169bd2d1e46fd57"
  #      }
  #    ],
  #    "sha" => "5ffdd99905664ba68a33b984ec9f58b57fe8d126",
  #    "stats" => %{"additions" => 1, "deletions" => 1, "total" => 2},
  #    "url" => "https://api.github.com/repos/crevalle/mrgr/commits/5ffdd99905664ba68a33b984ec9f58b57fe8d126"
  #    }
end
