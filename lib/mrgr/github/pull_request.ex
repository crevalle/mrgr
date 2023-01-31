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
  end
end
