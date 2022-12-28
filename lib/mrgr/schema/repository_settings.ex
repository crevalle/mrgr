defmodule Mrgr.Schema.RepositorySettings do
  use Mrgr.Schema

  @primary_key false
  embedded_schema do
    field(:dismiss_stale_reviews, :boolean, default: true)
    field(:required_approving_review_count, :integer, default: 0)

    field(:merge_commit_allowed, :boolean, default: false)
    field(:rebase_merge_allowed, :boolean, default: false)
    field(:squash_merge_allowed, :boolean, default: true)

    field(:default_branch_name, :string, default: "main")

    # primary branch protection
    field(:allows_force_pushes, :boolean, default: false)
    field(:allows_deletions, :boolean, default: false)
    field(:is_admin_enforced, :boolean, default: true)
    field(:requires_approving_reviews, :boolean, default: false)
    field(:requires_code_owner_reviews, :boolean, default: false)
    field(:requires_status_checks, :boolean, default: false)
    field(:requires_strict_status_checks, :boolean, default: false)
    field(:restricts_pushes, :boolean, default: false)

    embeds_many :push_allowances, PushAllowance, on_replace: :delete do
      # heterogenous data, depends on the type
      field(:type, :string)
      field(:data, :map)
    end

    embeds_many :required_status_checks, RequiredStatusCheck, on_replace: :delete do
      # "app" => %{"description" => "", "name" => "GitHub Code Scanning"},
      field(:app, :map)
      field(:context, :string)
    end
  end

  @fields ~w(
    dismiss_stale_reviews
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
    |> cast_embed(:required_status_checks, with: &required_status_checks_changeset/2)
    |> cast_embed(:push_allowances, with: &push_allowances_changeset/2)
    |> validate_inclusion(:required_approving_review_count, 0..10)
  end

  def required_status_checks_changeset(schema, params) do
    schema
    |> cast(params, [:app, :context])
  end

  def push_allowances_changeset(schema, params) do
    schema
    |> cast(params, [:data, :type])
  end

  def match?(one, two) do
    Enum.all?(@matching_fields, fn field -> match?(one, two, field) end)
  end

  def match?(one, two, :required_approving_review_count = field) do
    # nils and 0s are equal
    Map.get(one, field, 0) == Map.get(two, field, 0)
  end

  def match?(one, two, field) do
    Map.get(one, field) == Map.get(two, field)
  end

  def translate_branch_protection_to_rest_api(settings, repo_settings) do
    # just keep the repo settings for items we don't have a form for
    %{
      enforce_admins: repo_settings.is_admin_enforced,
      required_status_checks: translate_required_status_checks(repo_settings),
      restrictions: translate_restrictions(repo_settings),
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

  def translate_required_status_checks(%{requires_status_checks: false}), do: nil

  def translate_required_status_checks(settings) do
    checks = Enum.map(settings.required_status_checks, fn check -> %{context: check.context} end)

    %{
      strict: settings.requires_strict_status_checks,
      checks: checks
    }
  end

  def translate_restrictions(%{push_allowances: []}), do: nil

  def translate_restrictions(%{push_allowances: allowances}) do
    users =
      for a <- allowances, a.type == "user" do
        a.data["login"]
      end

    teams =
      for a <- allowances, a.type == "team" do
        a.data["slug"]
      end

    apps =
      for a <- allowances, a.type == "app" do
        a.data["slug"]
      end

    %{users: users, teams: teams, apps: apps}
  end

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

  def translate_graphql_params(data) do
    main = %{
      merge_commit_allowed: data["mergeCommitAllowed"],
      rebase_merge_allowed: data["rebaseMergeAllowed"],
      squash_merge_allowed: data["squashMergeAllowed"],
      default_branch_name: parse_default_branch_name(data)
    }

    protection = branch_protection_params(data["defaultBranchRef"]["branchProtectionRule"])

    Map.merge(main, protection)
  end

  # if no code has been pushed
  def parse_default_branch_name(%{"defaultBranchRef" => %{"name" => name}}), do: name
  def parse_default_branch_name(_), do: nil

  def branch_protection_params(nil) do
    %{
      required_approving_review_count: 0
    }
  end

  def branch_protection_params(map) do
    %{
      allows_deletions: map["allowsDeletions"],
      allows_force_pushes: map["allowsForcePushes"],
      dismiss_stale_reviews: map["dismissesStaleReviews"],
      is_admin_enforced: map["isAdminEnforced"],
      push_allowances: translate_push_allowances(map["pushAllowances"]),
      required_approving_review_count: map["requiredApprovingReviewCount"],
      required_status_checks: map["requiredStatusChecks"],
      requires_approving_reviews: map["requiresApprovingReviews"],
      requires_code_owner_reviews: map["requiresCodeOwnerReviews"],
      requires_status_checks: map["requiresStatusChecks"],
      requires_strict_status_checks: map["requiresStrictStatusChecks"],
      restricts_pushes: map["restrictsPushes"]
    }
  end

  def translate_push_allowances(%{"nodes" => node}) do
    # we don't translate since the names are simple,
    # we just inject the actor type into the data
    Enum.map(node, fn %{"actor" => data} ->
      %{"type" => actor_type(data), "data" => data}
    end)
  end

  def actor_type(%{"login" => _login}), do: "user"
  def actor_type(%{"membersUrl" => _login}), do: "team"
  def actor_type(_app), do: "app"
end
