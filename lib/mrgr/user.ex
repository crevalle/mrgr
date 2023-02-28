defmodule Mrgr.User do
  alias Mrgr.Schema.User, as: Schema
  alias Mrgr.User.Query, as: Query

  def wanting_pr_summary do
    Schema
    |> Query.wanting_pr_summary()
    |> Mrgr.Repo.all()
  end

  def all do
    Schema
    |> Query.with_current_installation()
    |> Query.cron()
    |> Mrgr.Repo.all()
  end

  @spec find(Ecto.Schema.t() | integer()) :: Schema.t() | nil
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
          {:ok, Schema.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_from_github(user_data, auth_token) do
    params = Mrgr.User.Github.generate_params(user_data, auth_token)

    case find_from_github_params(params) do
      %Schema{} = user ->
        user
        |> welcome_back(params)
        |> associate_member()
        |> set_tokens(params)
        |> Mrgr.Tuple.ok()

      nil ->
        Logger.warn("create user: #{inspect(params)}")
        create(params)
    end
  end

  def find_member(member_id) do
    Mrgr.Schema.Member
    |> Query.by_external_id(member_id)
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

  def set_current_installation(user, nil) do
    # first one is "current".  assume we have only one
    [current | _rest] = installations(user)

    set_current_installation(user, current)
  end

  def set_current_installation(user, installation) do
    params = %{current_installation_id: installation.id}

    user
    |> Schema.current_installation_changeset(params)
    |> Mrgr.Repo.update()
  end

  def installations(user) do
    user
    |> Query.installations()
    |> Mrgr.Repo.all()
  end

  def set_tokens(user, params) do
    user
    |> Schema.tokens_changeset(params)
    |> Mrgr.Repo.update!()
  end

  def associate_member(user) do
    case Mrgr.Repo.get_by(Mrgr.Schema.Member, login: user.nickname) do
      %Mrgr.Schema.Member{user_id: nil} = member ->
        member
        |> Mrgr.Schema.Member.changeset(%{user_id: user.id})
        |> Mrgr.Repo.update!()

      nil ->
        # TODO: create_member!()
        nil
        user

      _associated_member ->
        nil

        user
    end
  end

  def repos(user) do
    user
    |> Query.repos()
    |> Query.alphabetically()
    |> Mrgr.Repo.all()
  end

  def send_pr_summary(user) do
    closed_last_week_count = Mrgr.PullRequest.closed_last_week_count(user.current_installation_id)

    user.current_installation_id
    |> Mrgr.PullRequest.closed_this_week()
    |> Mrgr.Email.send_pr_summary(closed_last_week_count, user)
    |> Mrgr.Mailer.deliver()
  end

  def member(user) do
    Mrgr.Repo.get_by(Mrgr.Schema.Member, user_id: user.id)
  end

  def desmond do
    Mrgr.Repo.get_by(Schema, nickname: "desmondmonster")
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

    def installations(%{id: user_id}) do
      from(q in Mrgr.Schema.Installation,
        join: u in assoc(q, :users),
        where: u.id == ^user_id
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
        preload: [installations: i]
      )
    end

    def wanting_pr_summary(query) do
      from(q in query,
        where: q.send_weekly_summary_email == true
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
  end
end
