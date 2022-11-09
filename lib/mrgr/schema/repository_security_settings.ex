defmodule Mrgr.Schema.RepositorySecuritySettings do
  use Mrgr.Schema

  @primary_key false
  embedded_schema do
    field(:dismiss_stale_reviews, :boolean)
    field(:require_code_owner_reviews, :boolean)
    field(:required_approving_review_count, :integer, default: 1)

    field(:merge_commit_allowed, :boolean, default: false)
    field(:rebase_merge_allowed, :boolean, default: false)
    field(:squash_merge_allowed, :boolean, default: true)

    field(:default_branch_name, :string)

    # primary branch protection
    field(:allows_force_pushes, :boolean)
    field(:allows_deletions, :boolean)
    field(:is_admin_enforced, :boolean)
    field(:requires_approving_reviews, :boolean)
    field(:requires_code_owner_reviews, :boolean)
    field(:requires_status_checks, :boolean)
    field(:requires_strict_status_checks, :boolean)
    field(:restricts_pushes, :boolean)
  end

  @fields ~w(
    dismiss_stale_reviews
    require_code_owner_reviews
    required_approving_review_count
    merge_commit_allowed
    rebase_merge_allowed
    squash_merge_allowed
    default_branch_name
    allows_force_pushes
    allows_deletions
    is_admin_enforced
    requires_approving_reviews
    requires_code_owner_reviews
    requires_status_checks
    requires_strict_status_checks
    restricts_pushes
  )a

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_inclusion(:required_approving_review_count, 0..10)
  end
end
