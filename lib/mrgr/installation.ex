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
    |> Mrgr.Worker.InstallationSetup.new()
    |> Oban.insert()

    installation
  end

  def complete_setup(installation) do
    installation
    |> broadcast(@installation_loading_members)
    |> create_members()
    |> broadcast(@installation_loading_repositories)
    |> create_repositories()
    |> broadcast(@installation_loading_pull_requests)
    |> hydrate_github_pull_request_data()
    |> mark_setup_completed()
    |> broadcast(@installation_setup_completed)
  end

  def mark_setup_completed(installation) do
    installation
    |> Ecto.Changeset.change(%{setup_completed: true})
    |> Mrgr.Repo.update!()
  end

  def create_members(installation) do
    # create memberships
    members = Mrgr.Github.API.fetch_members(installation)
    add_team_members(installation, members)

    installation
  end

  def refresh_security_settings(installation) do
    # assumes repos already exist locally, WILL NOT create new ones
    data = fetch_repo_security_settings(installation)
    repos = Mrgr.Repository.refresh_security_settings(data)

    %{installation | repositories: repos}
  end

  def fetch_repo_security_settings(_installation, acc, %{
        "viewer" => %{
          "repositories" => %{"pageInfo" => %{"hasNextPage" => false}, "nodes" => nodes}
        }
      }) do
    nodes ++ acc
  end

  def fetch_repo_security_settings(installation, acc, %{
        "viewer" => %{
          "repositories" => %{
            "pageInfo" => %{"hasNextPage" => true, "endCursor" => end_cursor},
            "nodes" => nodes
          }
        }
      }) do
    acc = nodes ++ acc

    response = Mrgr.Github.API.Live.repo_security_settings(installation, %{after: end_cursor})
    fetch_repo_security_settings(installation, acc, response)
  end

  # initial call
  def fetch_repo_security_settings(installation) do
    acc = []
    response = Mrgr.Github.API.Live.repo_security_settings(installation)
    fetch_repo_security_settings(installation, acc, response)
  end

  @spec create_repositories(Mrgr.Schema.Installation.t()) :: Mrgr.Schema.Installation.t()
  def create_repositories(installation) do
    # assumes repos have been deleted
    repositories = fetch_repositories(installation)

    installation =
      installation
      |> Mrgr.Schema.Installation.repositories_changeset(%{"repositories" => repositories})
      |> Mrgr.Repo.update!()

    repositories = Enum.map(installation.repositories, &Mrgr.Repository.hydrate_ancillary_data/1)

    %{installation | repositories: repositories}
  end

  def fetch_repositories(installation) do
    Mrgr.Github.API.fetch_repositories(installation)
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

  def refresh_pull_requests!(installation) do
    Mrgr.PullRequest.delete_installation_pull_requests(installation)

    hydrate_github_pull_request_data(installation)
  end

  def hydrate_github_pull_request_data(installation) do
    # assumes account and repositories have been preloaded

    # we already have the installation here, so we reverse preload it onto its children repositories
    # so they'll have it for their API calls
    repositories =
      installation.repositories
      |> Enum.map(fn r -> %{r | installation: installation} end)
      |> Enum.map(&Mrgr.Repository.fetch_and_store_open_pull_requests!/1)

    installation = %{installation | repositories: repositories}

    # this returns a list, not the installation
    Mrgr.MergeQueue.regenerate_pull_request_queue(installation)

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

  defp add_team_members(installation, github_members) do
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
