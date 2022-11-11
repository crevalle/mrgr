defmodule Mrgr.Schema.RepositorySettings do
  use Mrgr.Schema

  @primary_key false
  embedded_schema do
    field(:dismiss_stale_reviews, :boolean)
    field(:require_code_owner_reviews, :boolean)
    field(:required_approving_review_count, :integer, default: 1)

    field(:merge_commit_allowed, :boolean, default: false)
    field(:rebase_merge_allowed, :boolean, default: false)
    field(:squash_merge_allowed, :boolean, default: true)

    field(:default_branch_name, :string, default: "main")

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

  @matching_fields ~w(
    required_approving_review_count
    merge_commit_allowed
    rebase_merge_allowed
    squash_merge_allowed
  )a

  def changeset(schema, params) do
    schema
    |> cast(params, @fields)
    |> validate_inclusion(:required_approving_review_count, 0..10)
  end

  def match?(one, two) do
    @matching_fields
    |> Enum.all?(fn field ->
      Map.get(one, field) == Map.get(two, field)
    end)
  end

  def translate_branch_protection_to_rest_api(settings) do
    %{
      enforce_admins: settings.is_admin_enforced,
      required_status_checks: nil,
      restrictions: nil,
      required_pull_request_reviews: %{
        required_approving_review_count: settings.required_approving_review_count
      }
    }
  end

  def translate_branch_protection_from_rest_api(data) do
    %{
      is_admin_enforced: data["enforce_admins"]["enabled"],
      required_approving_review_count:
        data["required_pull_request_reviews"]["required_approving_review_count"]
    }
  end

  # %{
  # "allow_deletions" => %{"enabled" => false},
  # "allow_force_pushes" => %{"enabled" => false},
  # "allow_fork_syncing" => %{"enabled" => false},
  # "block_creations" => %{"enabled" => false},
  # "enforce_admins" => %{
  # "enabled" => false,
  # "url" => "https://api.github.com/repos/crevalle/black-book-server/branches/master/protection/enforce_admins"
  # },
  # "lock_branch" => %{"enabled" => false},
  # "required_conversation_resolution" => %{"enabled" => false},
  # "required_linear_history" => %{"enabled" => false},
  # "required_pull_request_reviews" => %{
  # "dismiss_stale_reviews" => false,
  # "require_code_owner_reviews" => false,
  # "require_last_push_approval" => false,
  # "required_approving_review_count" => 0,
  # "url" => "https://api.github.com/repos/crevalle/black-book-server/branches/master/protection/required_pull_request_reviews"
  # },
  # "required_signatures" => %{
  # "enabled" => false,
  # "url" => "https://api.github.com/repos/crevalle/black-book-server/branches/master/protection/required_signatures"
  # },
  # "url" => "https://api.github.com/repos/crevalle/black-book-server/branches/master/protection"
  # }

  def translate_names_to_rest_api(settings) do
    %{
      allow_squash_merge: settings.squash_merge_allowed,
      allow_merge_commit: settings.merge_commit_allowed,
      allow_rebase_merge: settings.rebase_merge_allowed
    }
  end

  def translate_names_from_rest_api(data) do
    %{
      squash_merge_allowed: data["allow_squash_merge"],
      merge_commit_allowed: data["allow_merge_commit"],
      rebase_merge_allowed: data["allow_rebase_merge"]
    }
  end
end
