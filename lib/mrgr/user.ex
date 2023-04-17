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
    |> Query.with_current_installation()
    |> Query.with_installations()
    |> Query.with_member()
    |> Mrgr.Repo.one()
  end

  def find_with_current_installation(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_current_installation()
    |> Mrgr.Repo.one()
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

        {:ok, user, :returning}

      nil ->
        case create(params) do
          {:ok, user} ->
            tell_desmond_someone_signed_up(params, user)

            case find_member(user) do
              nil ->
                {:ok, user, :new}

              member ->
                user =
                  user
                  |> associate_user_with_member(member)
                  |> make_all_repos_visible()
                  |> generate_default_custom_dashboard_tabs()

                {:ok, user, :invited}
            end

          error ->
            tell_desmond_someone_failed_to_sign_up(params, error)

            error
        end
    end
  end

  def invite_by_email(emails, installation) when is_list(emails) do
    Enum.map(emails, &invite_by_email(&1, installation))
  end

  def invite_by_email(email, installation) do
    mail = Mrgr.Email.invite_user_to_installation(email, installation)
    Mrgr.Mailer.deliver(mail)
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

  def generate_default_custom_dashboard_tabs(user) do
    # creates tabs for every installation the user is a member of.
    # ❗️ a user invited to one org will automatically join all the
    # other orgs we have accounts for, increasing their billing.  this should
    # be fixed so that an invited user only joins a specific accout.  For now
    # I don't think it's a big problem so I'll fix it later and refund someone $25.

    user
    |> Mrgr.Installation.for_user()
    |> Enum.map(fn i ->
      Mrgr.PRTab.create_default_tabs(user.id, i.id, user.member)
    end)

    user
  end

  def associate_user_with_member(user, member) do
    member = Mrgr.Member.associate_with_user(member, user)

    user = %{user | member: member}

    reset_current_installation(user)
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

    user
    |> Mrgr.PullRequest.closed_this_week()
    |> Mrgr.Email.send_changelog(closed_last_week_count, user)
    |> Mrgr.Mailer.deliver()
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
  end

  def tell_desmond_someone_failed_to_sign_up(params, error) do
    params
    |> Mrgr.Email.hey_desmond_a_busted_user(error)
    |> Mrgr.Mailer.deliver()
  end

  def tell_desmond_someone_signed_up(params, user) do
    count = Mrgr.Repo.aggregate(Schema, :count)

    params
    |> Mrgr.Email.hey_desmond_another_user(count, user)
    |> Mrgr.Mailer.deliver()
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
  end
end
