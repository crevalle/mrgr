defmodule Mrgr.User do
  alias Mrgr.Schema.User, as: Schema
  alias Mrgr.User.Query, as: Query

  @spec find(Ecto.Schema.t() | integer()) :: Schema.t() | nil
  def find(%Mrgr.Github.User{} = user) do
    Mrgr.Repo.get_by(Schema, nickname: user.login)
  end

  def find(id) do
    Mrgr.Repo.get(Schema, id)
  end

  def find_with_current_installation(id) do
    Schema
    |> Query.by_id(id)
    |> Query.with_current_installation()
    |> Mrgr.Repo.one()
  end

  @spec find_or_create_from_github(Ueberauth.Auth.t()) :: Schema.t()
  def find_or_create_from_github(auth) do
    params = Mrgr.User.Github.generate_params(auth)

    case find_by_email(params.email) do
      %Schema{} = user ->
        set_tokens(user, params)

      nil ->
        {:ok, user} = create(params)
        user
    end
    |> IO.inspect()
  end

  @spec find_by_email(String.t()) :: Schema.t() | nil
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

  def repos(user) do
    user
    |> Query.repos()
    |> Mrgr.Repo.all()
  end

  defmodule Query do
    use Mrgr.Query

    def repos(%{id: user_id}) do
      from(q in Mrgr.Schema.Repository,
        left_join: m in assoc(q, :merges),
        join: u in assoc(q, :users),
        preload: [merges: m],
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
  end
end
