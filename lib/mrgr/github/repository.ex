defmodule Mrgr.Github.Repository do
  use Mrgr.Github.Schema

  embedded_schema do
    field(:full_name, :string)
    field(:id, :integer)
    field(:name, :string)
    field(:node_id, :string)
    field(:private, :boolean)
  end

  defmodule GraphQL do
    def basic do
      """
      id
      name
      """
    end

    def settings do
      """
      mergeCommitAllowed
      rebaseMergeAllowed
      squashMergeAllowed
      isPrivate
      parent {
        nameWithOwner
        name
        id
      }
      defaultBranchRef {
        name
        branchProtectionRule {
          allowsForcePushes
          allowsDeletions
          dismissesStaleReviews
          isAdminEnforced
          pushAllowances(first: 50) {
            nodes {
              actor  {
                ... on User #{Mrgr.Github.User.GraphQL.user()}
                ... on App #{Mrgr.Github.User.GraphQL.app()}
                ... on Team #{Mrgr.Github.User.GraphQL.team()}
              }
            }
          }
          requiresApprovingReviews
          requiredApprovingReviewCount
          requiresCodeOwnerReviews
          requiresStatusChecks
          requiresStrictStatusChecks
          restrictsPushes
          matchingRefs(first: 50) {
            nodes {
              name
            }
          }
          requiredStatusChecks {
            app {
              name
              description
            }
            context
          }
        }
      }
      labels(first: 99) {
        nodes {
          color
          name
        }
      }
      languages(first: 99) {
        edges {
          size
          node {
            color
            name
          }
        }
      }
      """
    end

    def primary_language do
      """
      primaryLanguage {
        color
        name
      }
      """
    end
  end

  # field(:full_name" => "crevalle/mother_brain",
  # field(:id" => 66312740,
  # field(:name" => "mother_brain",
  # field(:node_id" => "MDEwOlJlcG9zaXRvcnk2NjMxMjc0MA==",
  # field(:private" => true
end
