defmodule Mrgr.Installation do
  use Mrgr.PubSub.Event

  alias Mrgr.Schema.Installation, as: Schema
  alias Mrgr.Installation.Query

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

  def find_for_setup(id) do
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
    |> Query.with_repositories()
    |> Query.with_creator()
    |> Query.with_users()
    |> Mrgr.Repo.one()
  end

  def create_from_webhook(payload) do
    payload
    |> create_installation()
    |> queue_initial_setup()
    |> Mrgr.Tuple.ok()
  end

  defp find_user_from_webhook_sender(payload) do
    payload
    |> Map.get("sender")
    |> Mrgr.Github.User.new()
    |> Mrgr.User.find()
  end

  defp create_installation(payload) do
    creator = find_user_from_webhook_sender(payload)

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(%{"creator_id" => creator.id})
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    Mrgr.User.set_current_installation(creator, installation)

    installation
  end

  def queue_initial_setup(installation) do
    %{id: installation.id}
    |> Mrgr.Installation.Facilitator.new()
    |> Oban.insert()

    installation
  end

  def complete_setup(installation) do
    installation
    |> Mrgr.Repository.create_for_installation()
    |> hydrate_new_installation_data_from_github()
    |> mark_setup_completed()
    |> broadcast(@installation_setup_completed)
  end

  def mark_setup_completed(installation) do
    installation
    |> Ecto.Changeset.change(%{setup_completed: true})
    |> Mrgr.Repo.update!()
  end

  def hydrate_new_installation_data_from_github(installation) do
    # assumes account and repositories have been preloaded

    # create memberships
    members = Mrgr.Github.API.fetch_members(installation)
    add_team_members(installation, members)

    hydrate_github_merge_data(installation)
  end

  def delete_from_webhook(payload) do
    external_id = payload["installation"]["id"]

    Mrgr.Schema.Installation
    |> Mrgr.Repo.get_by(external_id: external_id)
    |> case do
      nil ->
        nil

      installation ->
        Mrgr.Repo.delete(installation)
    end
  end

  def refresh_merges!(installation) do
    Mrgr.Merge.delete_installation_merges(installation)

    hydrate_github_merge_data(installation)
  end

  def hydrate_github_merge_data(installation) do
    # we already have the data here, so we manually preloading the associations
    # to avoid passing redundant data separately further down the stack
    repositories =
      Enum.map(installation.repositories, fn r -> %{r | installation: installation} end)

    installation = %{installation | repositories: repositories}

    Mrgr.Repository.fetch_and_store_open_merges!(installation.repositories)

    # this returns a list, not the installation
    Mrgr.MergeQueue.regenerate_merge_queue(installation)

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

  def add_team_members(installation, github_members) do
    members = Enum.map(github_members, &find_or_create_member/1)
    Enum.map(members, &create_membership(installation, &1))

    members
  end

  def create_membership(installation, member) do
    params = %{member_id: member.id, installation_id: installation.id}

    params
    |> Mrgr.Schema.Membership.changeset()
    |> Mrgr.Repo.insert()
  end

  def find_or_create_member(github_member) do
    Mrgr.Schema.Member
    |> Mrgr.Repo.get_by(login: github_member.login)
    |> case do
      %Mrgr.Schema.Member{} = member ->
        member

      nil ->
        {:ok, member} = create_member_from_github(github_member)
        member
    end
  end

  def create_member_from_github(github_member) do
    existing_user = Mrgr.User.find(github_member)

    github_member
    |> Map.from_struct()
    |> maybe_associate_with_existing_user(existing_user)
    |> Mrgr.Schema.Member.changeset()
    |> Mrgr.Repo.insert()
  end

  def maybe_associate_with_existing_user(attrs, nil), do: attrs

  def maybe_associate_with_existing_user(attrs, %{id: id}) do
    Map.put(attrs, :user_id, id)
  end

  def find_by_external_id(external_id) do
    Schema
    |> Query.by_external_id(external_id)
    |> Mrgr.Repo.one()
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

  def delete_all do
    Mrgr.Repo.all(Mrgr.Schema.Installation) |> Enum.map(&Mrgr.Repo.delete/1)
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
  end
end
