defmodule Mrgr.Github.PullRequest do
  def commit_data(node) do
    Enum.map(node["commits"]["nodes"], & &1["commit"])
  end

  def filepaths(node) do
    Enum.map(node["files"]["nodes"], & &1["path"])
  end

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
  end
end
