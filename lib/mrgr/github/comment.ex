defmodule Mrgr.Github.Comment do
  defmodule GraphQL do
    def full do
      # for some reason this actor doesn't have an id
      """
      author {
        #{Mrgr.Github.User.GraphQL.actor_sans_id()}
      }
      body
      publishedAt
      url
      """
    end
  end
end
