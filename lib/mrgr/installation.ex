defmodule Mrgr.Installation do
  use Mrgr.PubSub.Event

  import Mrgr.Tuple, only: [ok: 1]

  alias Mrgr.Schema.Installation, as: Schema
  alias Mrgr.Installation.{Query, State, SubscriptionState}

  require Logger

  def find(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_account()
    |> Mrgr.Repo.one()
  end

  def find_for_account_page(user_id) do
    Schema
    |> Query.for_user(user_id)
    |> Query.with_account()
    |> Query.with_users()
    |> Mrgr.Repo.all()
  end

  def all do
    Schema
    |> Query.all()
    |> Query.with_account()
    |> Mrgr.Repo.all()
  end

  def all_admin do
    Schema
    |> Query.all()
    |> Query.with_account()
    |> Query.with_repositories()
    |> Query.with_creator()
    |> Mrgr.Repo.all()
  end

  def find_for_onboarding(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_account()
    |> Query.with_creator()
    |> Query.with_repositories()
    |> Mrgr.Repo.one()
  end

  def find_admin(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_account()
    |> Query.with_creator()
    |> Query.with_users()
    |> Query.with_subscription()
    |> Mrgr.Repo.one()
  end

  def create_from_webhook(payload) do
    case debounce_duplicate_create_webhook(payload) do
      :ok ->
        payload
        |> create_installation()
        |> queue_initial_setup()
        |> ok()

      {:error, _reason, installation} ->
        {:ok, installation}
    end
  end

  def debounce_duplicate_create_webhook(payload) do
    case find_by_external_id(payload["installation"]["id"]) do
      nil -> :ok
      installation -> {:error, :installation_exists, installation}
    end
  end

  defp find_user_from_webhook_sender(payload) do
    user_attrs = payload["requester"] || payload["sender"]

    user_attrs
    |> Mrgr.Github.User.new()
    |> Mrgr.User.find()
  end

  defp create_installation(payload) do
    creator = find_user_from_webhook_sender(payload)

    default_params = %{
      "creator_id" => creator.id,
      "state" => State.initial(),
      "subscription_state" => SubscriptionState.initial()
    }

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(default_params)
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    topic = Mrgr.PubSub.Topic.onboarding(creator)
    Mrgr.PubSub.broadcast(installation, topic, @installation_created)

    # user <> installation onboarding
    creator
    |> Mrgr.User.set_current_installation(installation)
    |> Mrgr.User.create_notification_address_at_current_installation()

    activate_subscriptions_on_personal_accounts(installation)
  end

  def queue_initial_setup(installation) do
    %{id: installation.id}
    |> Mrgr.Worker.InstallationOnboarding.new()
    |> Oban.insert()

    installation
  end

  def queue_closed_pr_sync(installation) do
    Mrgr.Worker.InstallationOnboarding.queue_sync_closed_prs(installation)

    installation
  end

  def onboard(i) do
    i
    |> clear_installation_data()
    |> State.reset_onboarding_error!()

    i = find_for_onboarding(i.id)

    with {:ok, i} <- onboard_members(i),
         {:ok, i} <- onboard_teams(i),
         {:ok, i} <- onboard_repos(i),
         {:ok, i} <- onboard_prs(i) do
      i
      |> State.onboarding_complete!()
      |> broadcast(@installation_onboarding_progressed)
    end
  end

  def onboard_members(installation) do
    try do
      installation
      |> State.onboarding_members!()
      |> broadcast(@installation_onboarding_progressed)
      |> create_members()
      |> create_user_defaults()
      |> ok()
    rescue
      e ->
        onboarding_failed!(installation, e, __STACKTRACE__, :onboarding_members_failed)
    end
  end

  def onboard_teams(installation) do
    try do
      installation
      |> State.onboarding_teams!()
      |> broadcast(@installation_onboarding_progressed)
      |> create_teams()
      |> ok()
    rescue
      e ->
        onboarding_failed!(installation, e, __STACKTRACE__, :onboarding_teams_failed)
    end
  end

  def onboard_repos(installation) do
    try do
      installation
      |> State.onboarding_repos!()
      |> broadcast(@installation_onboarding_progressed)
      |> sync_repos()
      |> ok()
    rescue
      e ->
        onboarding_failed!(installation, e, __STACKTRACE__, :onboarding_repos_failed)
    end
  end

  def onboard_prs(installation) do
    try do
      installation
      |> State.onboarding_prs!()
      |> broadcast(@installation_onboarding_progressed)
      |> sync_open_pull_requests()
      |> queue_closed_pr_sync()
      |> ok()
    rescue
      e ->
        onboarding_failed!(installation, e, __STACKTRACE__, :onboarding_prs_failed)
    end
  end

  def onboarding_failed!(installation, exception, trace, step) do
    str = "#{Exception.message(exception)}\n\n#{Exception.format_stacktrace(trace)}"

    Appsignal.set_error(exception, trace)

    installation
    |> State.onboarding_error!(str)
    |> broadcast(@installation_onboarding_progressed)
    |> Mrgr.Desmond.installation_data_sync_failed(str, step)

    {:error, step}
  end

  def create_user_defaults(installation) do
    Mrgr.PRTab.create_defaults_for_new_installation(installation)
    Mrgr.Notification.create_default_preferences_for_installation(installation)

    installation
  end

  defdelegate subscribed?(i), to: SubscriptionState
  defdelegate trial_period?(i), to: SubscriptionState

  def trial_period_length_in_days, do: 14

  def trial_time_left(installation) do
    elapsed = DateTime.diff(Mrgr.DateTime.now(), installation.inserted_at, :day)
    trial_period_length_in_days() - elapsed
  end

  defdelegate onboarded?(i), to: State

  def activate_subscription!(installation) do
    installation
    |> SubscriptionState.active!()
    |> broadcast(@installation_subscription_updated)
  end

  def activate_subscriptions_on_personal_accounts(%{target_type: "User"} = installation) do
    Mrgr.Installation.activate_subscription!(installation)
  end

  def activate_subscriptions_on_personal_accounts(installation), do: installation

  def add_slack_integration(installation, params, user) do
    # right now we only have the slack ID for the installing user,
    # so we only enable notifications for them and not any other users
    # at the installation

    installation = set_slackbot_info(installation, params)

    Mrgr.Notification.enable_slack_notifications(user, installation)

    Mrgr.Notification.Welcome.send_via_slack(user)

    installation
  end

  def remove_slack_integration(installation) do
    set_slackbot_info(installation, nil)

    # only one user (the installer) should have these turned on
    # but it's simpler to run through them all.  they'll all need
    # them turned off anyway.
    #
    # decided against leaving them enabled and just removing the slackbot
    # because if a real user (ie, not me in testing) has removed the slackbot,
    # they are probably not going to reinstall it
    installation = Mrgr.Repo.preload(installation, :users)

    Enum.map(installation.users, fn user ->
      Mrgr.Notification.disable_slack_notifications(user, installation)
    end)

    installation
  end

  def set_slackbot_info(installation, params) do
    installation
    |> Schema.slack_changeset(%{slackbot: params})
    |> Mrgr.Repo.update!()
  end

  # def slack_connected?(_), do: false
  def slack_connected?(%{slackbot: nil}), do: false
  def slack_connected?(_installation), do: true

  def hot_stats(installation) do
    member_count =
      installation.id
      |> Mrgr.Member.for_installation()
      |> Mrgr.Repo.count()

    repo_count =
      installation.id
      |> Mrgr.Repository.for_installation()
      |> Mrgr.Repo.count()

    pr_count =
      installation.id
      |> Mrgr.PullRequest.open_for_installation()
      |> Mrgr.Repo.count()

    %{members: member_count, repositories: repo_count, pull_requests: pr_count}
  end

  def create_members(%{target_type: "Organization"} = installation) do
    members = Mrgr.Github.API.fetch_members(installation)
    add_members(installation, members)

    installation
  end

  def create_members(installation) do
    # set creator as only member
    creator = Mrgr.User.find(installation.creator_id)

    with nil <- Mrgr.Member.find_by_login(creator.nickname),
         cs <- Mrgr.Schema.Member.changeset(creator),
         {:ok, member} <- Mrgr.Repo.insert(cs),
         {:ok, _membership} <- create_membership(installation, member) do
      :ok
    end

    installation
  end

  def create_teams(%{target_type: "Organization"} = installation) do
    teams = Mrgr.Github.API.fetch_teams(installation)
    add_teams(installation, teams)

    installation
  end

  def create_teams(installation) do
    # users don't have teams
    installation
  end

  # noop if they already exist
  def sync_repos(installation) do
    data = fetch_all_repository_data(installation)

    # look them all up at once, save possibly hundreds of db calls
    repos_by_node_id =
      installation
      |> Mrgr.Repository.all_for_installation()
      |> Enum.reduce(%{}, fn repo, acc ->
        # %{"<node_id>" => %Repository{}}
        Map.put(acc, repo.node_id, repo)
      end)

    repos =
      data
      |> Enum.map(&create_or_update_repository(repos_by_node_id, installation, &1))

    installation =
      installation
      |> mark_last_synced_at()
      |> broadcast(@installation_repositories_synced)

    %{installation | repositories: repos}
  end

  # works on our cached list.
  defp create_or_update_repository(repos, installation, node) do
    case Map.get(repos, node["id"]) do
      nil ->
        # cheat a bit
        other_params = %{
          installation_id: installation.id,
          full_name: "#{installation.account.login}/#{node["name"]}"
        }

        other_params
        |> Mrgr.Repository.create_from_graphql(node)

      repo ->
        Mrgr.Repository.update_from_graphql(repo, node)
    end
  end

  def clear_installation_data(installation) do
    clear_pull_requests(installation)
    Mrgr.Repository.delete_all_for_installation(installation)
    Mrgr.Team.delete_all_for_installation(installation)
    Mrgr.Member.delete_all_for_installation(installation)
    Mrgr.Notification.delete_all_for_installation(installation)
    Mrgr.PRTab.delete_all_for_installation(installation)

    installation
  end

  def recreate_repositories(installation) do
    # does not load PR data, just repo data
    Mrgr.Repository.delete_all_for_installation(installation)
    sync_repos(installation)
  end

  def fetch_all_repository_data(_installation, acc, %{
        "viewer" => %{
          "repositories" => %{"pageInfo" => %{"hasNextPage" => false}, "nodes" => nodes}
        }
      }) do
    nodes ++ acc
  end

  def fetch_all_repository_data(installation, acc, %{
        "viewer" => %{
          "repositories" => %{
            "pageInfo" => %{"hasNextPage" => true, "endCursor" => end_cursor},
            "nodes" => nodes
          }
        }
      }) do
    acc = nodes ++ acc

    response = Mrgr.Github.API.fetch_all_repository_data(installation, %{after: end_cursor})
    fetch_all_repository_data(installation, acc, response)
  end

  def fetch_all_repository_data(_installation, acc, _response) do
    acc
  end

  # initial call
  def fetch_all_repository_data(installation) do
    acc = []
    response = Mrgr.Github.API.fetch_all_repository_data(installation)
    fetch_all_repository_data(installation, acc, response)
  end

  def delete_from_webhook(payload) do
    external_id = payload["installation"]["id"]

    Mrgr.Schema.Installation
    |> Mrgr.Repo.get_by(external_id: external_id)
    |> case do
      nil ->
        nil

      installation ->
        Mrgr.User.unset_current_installation_for_users(installation)
        Mrgr.Repo.delete(installation)
    end
  end

  def refresh_pull_requests!(installation) do
    clear_pull_requests(installation)

    sync_open_pull_requests(installation)
    sync_closed_pull_requests(installation)
  end

  def clear_pull_requests(installation) do
    Mrgr.PullRequest.delete_installation_pull_requests(installation)

    installation
  end

  # assumes PRs have been deleted
  # and account and repositories have been preloaded
  def sync_open_pull_requests(installation) do
    # ! does NOT return the PRs.
    installation.repositories
    |> Enum.map(fn r -> %{r | installation: installation} end)
    |> Enum.map(&Mrgr.Repository.sync_open_pull_requests/1)

    installation
  end

  def sync_closed_pull_requests(installation) do
    installation.repositories
    |> Enum.map(fn r -> %{r | installation: installation} end)
    |> Enum.map(&Mrgr.Repository.sync_recentish_closed_pull_requests/1)

    installation
  end

  def set_tokens(install, %Mrgr.Github.AccessToken{} = token) do
    params = %{
      token_expires_at: token.expires_at,
      token: token.token
    }

    set_tokens(install, params)
  end

  def set_tokens(install, params) do
    install
    |> Schema.tokens_changeset(params)
    |> Mrgr.Repo.update!()
  end

  defp add_members(installation, github_users) when is_list(github_users) do
    members = Enum.map(github_users, &Mrgr.Member.find_or_create_member/1)
    Enum.map(members, &create_membership(installation, &1))

    members
  end

  def create_membership(installation, member) do
    params = %{member_id: member.id, installation_id: installation.id}

    params
    |> Mrgr.Schema.Membership.changeset()
    |> Mrgr.Repo.insert()
  end

  def add_teams(installation, github_teams) when is_list(github_teams) do
    Enum.map(github_teams, &find_or_create_team(installation, &1))
  end

  def find_or_create_team(installation, github_team) do
    case Mrgr.Team.find_by_node_id(github_team.node_id) do
      nil ->
        github_team
        |> Mrgr.Github.Schema.to_attrs()
        |> Map.put(:installation_id, installation.id)
        |> Mrgr.Team.create!()

      team ->
        team
    end
  end

  def for_user(user) do
    Schema
    |> Query.for_user(user.id)
    |> Query.with_account()
    |> Mrgr.Repo.all()
  end

  def find_by_external_id(external_id) do
    Schema
    |> Query.by_external_id(external_id)
    |> Mrgr.Repo.one()
  end

  def mark_last_synced_at(installation) do
    installation
    |> Ecto.Changeset.change(%{
      repos_last_synced_at: Mrgr.DateTime.safe_truncate(Mrgr.DateTime.now())
    })
    |> Mrgr.Repo.update!()
  end

  def installation_url do
    Application.get_env(:mrgr, :installation)[:url]
  end

  def broadcast(installation, event) do
    topic = Mrgr.PubSub.Topic.installation(installation)
    Mrgr.PubSub.broadcast(installation, topic, event)

    installation
  end

  ### HELPERS
  def i do
    Mrgr.Schema.Installation
    |> Mrgr.Repo.all()
    |> List.first()
    |> Mrgr.Repo.preload(:account)
  end

  defmodule Query do
    use Mrgr.Query

    def all(query) do
      from(q in query,
        order_by: [desc: :inserted_at]
      )
    end

    def with_account(query) do
      from(q in query,
        join: a in assoc(q, :account),
        preload: [account: a]
      )
    end

    def with_repositories(query) do
      from(q in query,
        left_join: r in assoc(q, :repositories),
        preload: [repositories: r]
      )
    end

    def with_creator(query) do
      from(q in query,
        join: c in assoc(q, :creator),
        preload: [creator: c]
      )
    end

    def with_users(query) do
      from(q in query,
        left_join: u in assoc(q, :users),
        preload: [users: u]
      )
    end

    def with_subscription(query) do
      from(q in query,
        left_join: s in assoc(q, :subscription),
        preload: [subscription: s]
      )
    end

    def for_user(query, user_id) do
      from(q in query,
        join: u in assoc(q, :users),
        where: u.id == ^user_id
      )
    end
  end
end
