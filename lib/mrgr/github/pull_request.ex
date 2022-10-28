defmodule Mrgr.Github.PullRequest do
  defmodule GraphQL do
    def commit do
      """
      {
        additions
        abbreviated_oid
        oid
        author #{Mrgr.Github.User.GraphQL.git_actor()}
        authoredDate
        message
      }
      """
    end

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
