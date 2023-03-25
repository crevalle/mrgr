defmodule Mrgr.Github.PullRequest do
  defmodule GraphQL do
    def head_ref do
      """
      {
        id
        name
        target {
          oid
        }
      }
      """
    end

    def files do
      """
      {
        changeType
        path
      }
      """
    end

    def to_params(node) do
      %{
        additions: node["additions"],
        commits: commit_data(node),
        deletions: node["deletions"],
        draft: node["isDraft"],
        files_changed: filepaths(node),
        merge_state_status: node["mergeStateStatus"],
        mergeable: node["mergeable"],
        title: node["title"]
      }
    end

    # nb: we use string keys because we merge the data back in with the node params
    def heavy_pull_to_params(node) do
      author_id = find_member_id(node["author"]["id"])

      parsed = %{
        "author_id" => author_id,
        "assignees" => Mrgr.Github.User.graphql_to_attrs(node["assignees"]["nodes"]),
        "commits" => commit_data(node),
        "created_at" => node["createdAt"],
        "draft" => node["isDraft"],
        "files_changed" => filepaths(node),
        "head" => %{
          "node_id" => node["headRef"]["id"],
          "ref" => node["headRef"]["name"],
          "sha" => node["headRef"]["target"]["oid"]
        },
        "id" => node["databaseId"],
        "merged_at" => node["mergedAt"],
        "node_id" => node["id"],
        "requested_reviewers" => parse_requested_reviewers(node["reviewRequests"]["nodes"]),
        "status" => String.downcase(node["state"]),
        "url" => node["permalink"],
        "user" => %{
          "login" => node["author"]["login"],
          "avatar_url" => node["author"]["avatarUrl"]
        }
      }

      Map.merge(node, parsed)
    end

    def commit_data(nil), do: []

    def commit_data(node) do
      Enum.map(node["commits"]["nodes"], & &1["commit"])
    end

    def filepaths(node) do
      Enum.map(node["files"]["nodes"], & &1["path"])
    end

    def find_member_id(nil), do: nil

    def find_member_id(node_id) do
      case Mrgr.Member.find_by_node_id(node_id) do
        %{id: id} -> id
        nil -> nil
      end
    end

    def parse_requested_reviewers(nodes) do
      nodes
      |> Enum.map(&Map.get(&1, "requestedReviewer"))
      |> Enum.map(&Mrgr.Github.User.graphql_to_attrs/1)
    end
  end
end
