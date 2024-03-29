defmodule Mrgr.User do
  use Mrgr.PubSub.Event

  alias Mrgr.Schema.User, as: Schema
  alias Mrgr.User.Query, as: Query

  require Logger

  def wanting_changelog do
    Schema
    |> Query.wanting_changelog()
    |> Mrgr.Repo.all()
  end

  def all do
    Schema
    |> Query.with_current_installation()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  def all_regardless_of_installation do
    Schema
    |> Query.with_or_without_current_installation()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  @spec find(Ecto.Schema.t() | integer()) :: Schema.t() | nil
  def find(%Mrgr.Github.User{login: nil}), do: nil

  def find(%Mrgr.Github.User{} = user) do
    Mrgr.Repo.get_by(Schema, nickname: user.login)
  end

  def find(id) do
    Mrgr.Repo.get(Schema, id)
  end

  def find_full(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_or_without_current_installation()
    |> Query.with_installations()
    |> Query.with_member()
    |> Query.with_notification_preferences()
    |> Query.with_notification_addresses()
    |> Query.with_pr_tabs()
    |> Mrgr.Repo.one()
  end

  def find_with_current_installation(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_current_installation()
    |> Mrgr.Repo.one()
  end

  def with_installations do
    Schema
    |> Query.with_installations()
    |> Mrgr.Repo.all()
  end

  def unset_current_installation_for_users(installation) do
    Schema
    |> Query.where(current_installation_id: installation.id)
    |> Mrgr.Repo.all()
    |> Enum.map(&unset_current_installation/1)
  end

  def unset_current_installation(user) do
    user
    |> Ecto.Changeset.change(%{current_installation_id: nil})
    |> Mrgr.Repo.update!()
  end

  @spec find_or_create_from_github(%{required(String.t()) => any()}, OAuth2.AccessToken.t()) ::
          {:ok, Schema.t(), atom()} | {:error, Ecto.Changeset.t()}
  def find_or_create_from_github(user_data, auth_token) do
    params = Mrgr.User.Github.generate_params(user_data, auth_token)

    case find_from_github_params(params) do
      %Schema{} = user ->
        user =
          user
          |> preload_current_installation()
          |> welcome_back(params)
          |> set_tokens(params)

        # someone signs up but doesn't complete onboarding
        case user.current_installation do
          nil ->
            {:ok, user, :new}

          _installation ->
            {:ok, user, :returning}
        end

      nil ->
        case create(params) do
          {:ok, user} ->
            Mrgr.Desmond.someone_signed_up(params, user)

            {:ok, user, :new}

          error ->
            Mrgr.Desmond.someone_failed_to_sign_up(params, error)

            error
        end
    end
  end

  def find_member(%Schema{node_id: node_id}) do
    Mrgr.Member.find_by_node_id(node_id)
  end

  def find_member(member_id) do
    Mrgr.Schema.Member
    |> Query.by_external_id(member_id)
    |> Mrgr.Repo.one()
  end

  def find_from_member(%Mrgr.Schema.Member{} = member) do
    Schema
    |> Query.from_member(member)
    |> Mrgr.Repo.one()
  end

  def welcome_back(user, params) do
    user
    |> Schema.welcome_back_changeset(params)
    |> Mrgr.Repo.update!()
  end

  def find_from_github_params(params) do
    find_by_node_id(params["node_id"]) || find_by_email(params["email"])
  end

  def find_by_node_id(node_id) do
    Mrgr.Repo.get_by(Schema, node_id: node_id)
  end

  @spec find_by_email(String.t() | nil) :: Schema.t() | nil
  def find_by_email(nil), do: nil

  def find_by_email(email) do
    Mrgr.Repo.get_by(Schema, email: email)
  end

  @spec create(map()) :: {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params
    |> Schema.create_changeset()
    |> Mrgr.Repo.insert()
  end

  def preload_current_installation(user) do
    Mrgr.Repo.preload(user, current_installation: :account)
  end

  @spec reset_current_installation(Schema.t()) :: Schema.t()
  def reset_current_installation(user) do
    case Mrgr.Installation.for_user(user) do
      [] ->
        user

      # first one is "current"
      [current | _rest] ->
        set_current_installation(user, current)
    end
  end

  @spec set_current_installation(Schema.t(), Mrgr.Schema.Installation.t()) :: Schema.t()
  def set_current_installation(user, installation) do
    params = %{current_installation_id: installation.id}

    user =
      user
      |> Schema.current_installation_changeset(params)
      |> Mrgr.Repo.update!()

    topic = Mrgr.PubSub.Topic.user(user)
    Mrgr.PubSub.broadcast(installation, topic, @installation_switched)

    %{user | current_installation: installation}
  end

  def set_tokens(user, params) do
    user
    |> Schema.tokens_changeset(params)
    |> Mrgr.Repo.update!()
  end

  def make_all_repos_visible(user) do
    # expects none to be visible, ie a new user
    user
    |> Mrgr.Installation.for_user()
    |> Enum.map(fn i ->
      i
      |> Mrgr.Repo.preload(:repositories)
      |> Map.get(:repositories)
      |> Enum.each(fn repo ->
        Mrgr.Repository.make_repo_visible_to_user(repo, user)
      end)
    end)

    user
  end

  def set_slack_contact_at_installation(user, installation, slack_id) do
    pref = find_user_notification_address(user.id, installation.id)

    pref
    |> Mrgr.Schema.UserNotificationAddress.changeset(%{slack_id: slack_id})
    |> Mrgr.Repo.update!()
  end

  def find_user_notification_address(user) do
    find_user_notification_address(user.id, user.current_installation_id)
  end

  def find_user_notification_address(user_id, installation_id) do
    Mrgr.Schema.UserNotificationAddress
    |> Query.where(user_id: user_id)
    |> Query.where(installation_id: installation_id)
    |> Mrgr.Repo.one()
  end

  def notification_preferences(user) do
    Mrgr.Schema.UserNotificationPreference
    |> Query.where(user_id: user.id)
    |> Query.where(installation_id: user.current_installation_id)
    |> Query.order(desc: :event)
    |> Mrgr.Repo.all()
  end

  def generate_default_custom_dashboard_tabs(user) do
    # creates tabs for every installation the user is a member of.
    user
    |> Mrgr.Installation.for_user()
    |> Enum.map(fn i ->
      Mrgr.PRTab.create_default_tabs(user.id, i.id, user.member)
    end)

    user
  end

  def create_default_notifications(user) do
    Mrgr.Notification.create_default_preferences_for_user(user)

    user
  end

  def associate_user_with_member(user, member) do
    member = Mrgr.Member.associate_with_user(member, user)

    user = %{user | member: member}

    reset_current_installation(user)
  end

  def create_notification_address_at_current_installation(user) do
    Mrgr.Schema.UserNotificationAddress.create_for_user_and_installation(
      user,
      user.current_installation
    )
  end

  def repos(user) do
    user
    |> Query.repos()
    |> Query.alphabetically()
    |> Mrgr.Repo.all()
  end

  def for_installation(installation_id) do
    Schema
    |> Query.for_installation(installation_id)
    |> Mrgr.Repo.all()
  end

  def send_changelog(user) do
    closed_last_week_count = Mrgr.PullRequest.closed_last_week_count(user.current_installation_id)
    # skip linking this to pull requests

    user
    |> Mrgr.PullRequest.closed_this_week()
    |> Mrgr.Email.send_changelog(closed_last_week_count, user)
    |> Mrgr.Mailer.deliver_and_log("changelog")
  end

  def visible_repos_at_current_installation(user) do
    Query.uvrs_visible_to_user(user)
  end

  def admin_at_installation?(%{id: id, current_installation: %{creator_id: id}}), do: true
  def admin_at_installation?(_user), do: false

  def admin?(%{nickname: "desmondmonster"}), do: true
  def admin?(_user), do: false

  def desmond do
    Mrgr.Repo.get_by(Schema, nickname: "desmondmonster")
    |> Mrgr.Repo.preload(current_installation: :account)
  end

  defmodule Query do
    use Mrgr.Query

    def repos(%{id: user_id}) do
      from(q in Mrgr.Schema.Repository,
        left_join: m in assoc(q, :pull_requests),
        join: u in assoc(q, :users),
        preload: [pull_requests: m],
        where: u.id == ^user_id
      )
    end

    def uvrs_visible_to_user(user) do
      from(q in Mrgr.Schema.UserVisibleRepository,
        join: r in assoc(q, :repository),
        where: q.user_id == ^user.id,
        where: r.installation_id == ^user.current_installation_id
      )
    end

    def for_installation(query, installation_id) do
      from(q in query,
        left_join: i in assoc(q, :installations),
        where: i.id == ^installation_id
      )
    end

    # mostly for legacy stuff, users should always have a current installation,
    # except for the brief moment from when they sign up and before they install
    # our GH app.  this should be used ONLY for admin stuff.
    def with_or_without_current_installation(query) do
      from(q in query,
        left_join: c in assoc(q, :current_installation),
        left_join: a in assoc(c, :account),
        preload: [current_installation: {c, account: a}]
      )
    end

    def with_current_installation(query) do
      from(q in query,
        left_join: c in assoc(q, :current_installation),
        left_join: a in assoc(c, :account),
        preload: [current_installation: {c, account: a}]
      )
    end

    def with_installations(query) do
      from(q in query,
        left_join: i in assoc(q, :installations),
        left_join: a in assoc(i, :account),
        preload: [installations: {i, account: a}]
      )
    end

    def with_notification_preferences(query) do
      from(q in query,
        left_join: p in assoc(q, :notification_preferences),
        preload: [notification_preferences: p]
      )
    end

    def with_notification_addresses(query) do
      from(q in query,
        left_join: p in assoc(q, :notification_addresses),
        preload: [notification_addresses: p]
      )
    end

    def wanting_changelog(query) do
      from(q in query,
        where: q.send_weekly_changelog_email == true,
        where: not is_nil(q.current_installation_id)
      )
    end

    def alphabetically(query) do
      from(q in query,
        order_by: [asc: :name]
      )
    end

    def with_member(query) do
      from(q in query,
        left_join: m in assoc(q, :member),
        preload: [member: m]
      )
    end

    def from_member(query, member) do
      from(q in query,
        join: m in assoc(q, :member),
        where: m.id == ^member.id
      )
    end

    def with_pr_tabs(query) do
      from(q in query,
        left_join: t in assoc(q, :pr_tabs),
        preload: [pr_tabs: t]
      )
    end
  end
end
