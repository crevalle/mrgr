defmodule Mrgr.HighImpactFileRule do
  @name "hif"

  alias Mrgr.Schema.HighImpactFileRule, as: Schema
  alias __MODULE__.Query

  use Mrgr.PubSub.Event

  def for_user(user) do
    for_user_at_installation(user.id, user.current_installation_id)
  end

  def for_user_with_repo(user) do
    Schema
    |> Query.for_user(user.id)
    |> Query.for_installation(user.current_installation_id)
    |> Query.with_repository()
    |> Mrgr.Repo.all()
  end

  def for_user_at_installation(user_id, installation_id) do
    Schema
    |> Query.for_user(user_id)
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.all()
  end

  @doc "gets all HIFs on the repository and returns those applicable to the PR"
  def for_pull_request(
        %{repository: %{high_impact_file_rules: %Ecto.Association.NotLoaded{}}} = pull_request
      ) do
    repo = Mrgr.Repo.preload(pull_request.repository, :high_impact_file_rules)
    pull_request = %{pull_request | repository: repo}

    for_pull_request(pull_request)
  end

  def for_pull_request(%{repository: %{high_impact_file_rules: rules}} = pull_request) do
    for_pull_request(rules, pull_request)
  end

  def for_pull_request(rules, pull_request) do
    rules
    |> Enum.filter(&applies_to_pull_request?(&1, pull_request))
    |> Enum.uniq_by(& &1.id)
  end

  def clear_from_pr(pull_request) do
    pull_request = Mrgr.Repo.preload(pull_request, :high_impact_file_rule_pull_requests)

    pull_request.high_impact_file_rule_pull_requests
    |> Enum.map(&Mrgr.Repo.delete/1)

    %{pull_request | high_impact_file_rule_pull_requests: [], high_impact_file_rules: []}
  end

  def reset(%Mrgr.Schema.PullRequest{} = pull_request) do
    reset(pull_request.repository, pull_request)
  end

  def reset(%Mrgr.Schema.Repository{high_impact_file_rules: rules}, pull_request) do
    reset(rules, pull_request)
  end

  def reset(rules, pull_request) do
    pull_request = clear_from_pr(pull_request)

    # since we're clearing PRs these should all be created successfully
    assocs =
      rules
      |> for_pull_request(pull_request)
      |> Enum.map(fn hif -> create_for_pull_request(hif, pull_request) end)
      |> Enum.map(fn {:ok, a} -> a end)

    %{pull_request | high_impact_file_rules: rules, high_impact_file_rule_pull_requests: assocs}
  end

  @spec create_for_pull_request(Schema.t(), Mrgr.Schema.PullRequest.t()) ::
          {:ok, Mrgr.Schema.HighImpactFileRulePullRequest.t()} | {:error, Ecto.Changeset.t()}
  def create_for_pull_request(hif, pull_request) do
    params = %{
      high_impact_file_rule_id: hif.id,
      pull_request_id: pull_request.id
    }

    %Mrgr.Schema.HighImpactFileRulePullRequest{}
    |> Mrgr.Schema.HighImpactFileRulePullRequest.changeset(params)
    |> Mrgr.Repo.insert()
  end

  def applies_to_pull_request?(hif, pull_request) do
    hif
    |> matching_filenames(pull_request)
    |> Enum.any?()
  end

  @spec hif_consumer_is_author?(Schema.t(), Mrgr.Schema.PullRequest.t()) :: boolean()
  def hif_consumer_is_author?(%{user_id: user_id}, %{user_id: user_id}), do: true
  def hif_consumer_is_author?(_hif, _pr), do: false

  def send_alert(%{high_impact_file_rules: []}), do: nil

  def send_alert(%{high_impact_file_rules: rules} = pull_request) when is_list(rules) do
    # each user gets one alert per pull request with all applicable rules
    pull_request = Mrgr.Repo.preload(pull_request, :author)

    rules
    # don't send alerts to whomever opened the PR
    |> Enum.reject(&hif_consumer_is_author?(&1, pull_request.author))
    |> Enum.group_by(& &1.user_id)
    |> Enum.map(&do_send_alert(&1, pull_request))
  end

  defp do_send_alert({user_id, rules}, pull_request) do
    recipient = Mrgr.User.find_with_current_installation(user_id)

    rules_by_channel =
      rules
      |> Enum.map(fn rule ->
        %{rule | filenames: matching_filenames(rule, pull_request)}
      end)
      |> Mrgr.Notification.bucketize_preferences()

    email_results = send_email_alert(rules_by_channel.email, recipient, pull_request)
    slack_results = send_slack_alert(rules_by_channel.slack, recipient, pull_request)

    %{email: email_results, slack: slack_results}
  end

  def send_email_alert([], _recipient, _pull_request), do: nil

  def send_email_alert(rules, recipient, pull_request) do
    email = Mrgr.Email.hif_alert(rules, recipient, pull_request)

    Mrgr.Mailer.deliver_and_log(email, @name)
  end

  def send_slack_alert([], _recipient, _pull_request), do: nil

  def send_slack_alert(rules, recipient, pull_request) do
    message = Mrgr.Slack.Message.HIFAlert.render(pull_request, rules)

    Mrgr.Slack.send_and_log(message, recipient, @name)
  end

  def matching_filenames(rule, pull_request) do
    filenames = pull_request.files_changed

    Enum.filter(filenames, &pattern_matches_filename?(&1, rule))
  end

  def pattern_matches_filename?(filename, %Schema{pattern: pattern}) do
    pattern_matches_filename?(filename, pattern)
  end

  def pattern_matches_filename?(filename, pattern) when is_bitstring(pattern) do
    PathGlob.match?(filename, pattern)
  end

  def delete(rule) do
    rule
    |> Mrgr.Repo.delete()
    |> case do
      {:ok, deleted} = res ->
        broadcast(deleted, @high_impact_file_rule_deleted)
        res

      {:error, _cs} = error ->
        error
    end
  end

  def create(params) do
    %Schema{}
    |> Schema.changeset(params)
    |> Mrgr.Repo.insert()
    |> case do
      {:ok, created} = res ->
        add_to_matching_open_prs(created)

        broadcast(created, @high_impact_file_rule_created)
        res

      {:error, _cs} = error ->
        error
    end
  end

  @spec add_to_matching_open_prs(Schema.t()) :: Schema.t()
  def add_to_matching_open_prs(hif) do
    prs = find_matching_open_prs(hif)

    Enum.map(prs, fn pull_request -> create_for_pull_request(hif, pull_request) end)

    hif
  end

  def update_matching_prs(hif) do
    remove_from_prs_that_no_longer_match(hif)

    add_to_matching_open_prs(hif)

    hif
  end

  def remove_from_prs_that_no_longer_match(hif) do
    hif = Mrgr.Repo.preload(hif, :pull_requests)

    remove_from_prs_that_no_longer_match(hif, hif.pull_requests)
  end

  def remove_from_prs_that_no_longer_match(hif, prs) do
    prs
    |> Enum.reject(&applies_to_pull_request?(hif, &1))
    |> Enum.map(&remove_from_pull_request(hif, &1))
  end

  def find_matching_open_prs(hif) do
    hif.repository_id
    |> Mrgr.PullRequest.open_for_repo_id()
    |> Mrgr.Repo.all()
    |> Enum.filter(&applies_to_pull_request?(hif, &1))
  end

  def remove_from_pull_request(hif, pull_request) do
    assoc = find_pr_assoc(hif, pull_request)

    Mrgr.Repo.delete(assoc)
  end

  def find_pr_assoc(hif, pull_request) do
    Mrgr.Schema.HighImpactFileRulePullRequest
    |> Query.for_hif_and_pr(hif, pull_request)
    |> Mrgr.Repo.one()
  end

  def create_user_defaults_for_repository(user, repository) do
    user
    |> user_defaults_for_repository(repository)
    |> Enum.map(&create/1)
  end

  def user_defaults_for_repository(user, repository) do
    repository
    |> defaults_for_repo()
    |> Enum.map(fn attrs ->
      attrs
      |> Map.put(:user_id, user.id)
      |> Map.put(:repository_id, repository.id)
    end)
  end

  def defaults_for_repo(%{language: "Elixir"}) do
    [
      %{
        name: "migration",
        pattern: "priv/repo/migrations/*",
        color: "#dcfce7",
        email: true,
        slack: false,
        source: :system
      },
      %{
        name: "router",
        pattern: "lib/**/router.ex",
        color: "#dbeafe",
        email: true,
        slack: false,
        source: :system
      },
      %{
        name: "dependencies",
        pattern: "mix.lock",
        color: "#fef9c3",
        email: true,
        slack: false,
        source: :system
      }
    ]
  end

  def defaults_for_repo(%{language: "Ruby"}) do
    [
      %{
        name: "migration",
        pattern: "db/migrate/*",
        color: "#dcfce7",
        email: true,
        slack: false,
        source: :system
      },
      %{
        name: "router",
        pattern: "config/routes.rb",
        color: "#dbeafe",
        email: true,
        slack: false,
        source: :system
      },
      %{
        name: "dependencies",
        pattern: "Gemfile.lock",
        color: "#fef9c3",
        email: true,
        slack: false,
        source: :system
      }
    ]
  end

  def defaults_for_repo(%{language: "Javascript"}) do
    [
      %{
        name: "dependencies",
        pattern: "package-lock.json",
        color: "#fef9c3",
        email: true,
        slack: false,
        source: :system
      }
    ]
  end

  def defaults_for_repo(_unsupported), do: []

  def update(hif, params) do
    hif
    |> Schema.update_changeset(params)
    |> Mrgr.Repo.update()
    |> case do
      {:ok, updated} = res ->
        update_matching_prs(updated)
        broadcast(updated, @high_impact_file_rule_updated)
        res

      {:error, _cs} = error ->
        error
    end
  end

  defp broadcast(hif, event) do
    hif = Mrgr.Repo.preload(hif, :repository)

    installation_id = hif.repository.installation_id
    topic = Mrgr.PubSub.Topic.installation(installation_id)

    Mrgr.PubSub.broadcast(hif, topic, event)
  end

  defmodule Query do
    use Mrgr.Query

    def for_user(query, user_id) do
      from(q in query,
        where: q.user_id == ^user_id
      )
    end

    def for_installation(query, installation_id) do
      from([q, repository: r] in with_repository(query),
        where: r.installation_id == ^installation_id
      )
    end

    def with_repository(query) do
      case has_named_binding?(query, :repository) do
        true ->
          query

        false ->
          from(q in query,
            join: r in assoc(q, :repository),
            as: :repository,
            preload: [repository: r]
          )
      end
    end

    def with_installation(query) do
      from(q in query,
        join: r in assoc(q, :repository),
        join: i in assoc(r, :installation),
        preload: [repository: {r, [installation: i]}]
      )
    end

    def order_by_pattern(query) do
      from(q in query,
        order_by: [desc: q.pattern]
      )
    end

    def for_hif_and_pr(query, hif, pr) do
      from(q in query,
        where: q.high_impact_file_rule_id == ^hif.id,
        where: q.pull_request_id == ^pr.id
      )
    end
  end
end
