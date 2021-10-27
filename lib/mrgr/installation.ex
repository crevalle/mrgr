defmodule Mrgr.Installation do
  alias Mrgr.Schema.Installation, as: Schema
  alias Mrgr.Installation.Query

  def create_from_webhook(payload) do
    repository_params = payload["repositories"]

    creator =
      payload
      |> Map.get("sender")
      |> Mrgr.Github.User.new()
      |> Mrgr.User.find()

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(%{"creator_id" => creator.id, "repositories" => repository_params})
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    Mrgr.User.set_current_installation(creator, installation)

    client = Mrgr.Github.Client.new(installation)

    # create memberships
    members = fetch_members(installation, client)
    add_team_members(installation, members)

    IO.inspect(installation, label: " ***INSTALL")
    # TODO repos
    Mrgr.Repository.fetch_and_store_open_merges!(installation.repositories, client)

    {:ok, installation}
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

  # assumes account has been preloaded
  # and install access token has been generated
  # later, find or create a token ..?
  # should we pass an account in, rather than an install?  what's the controlling entity?
  def fetch_members(installation, client) do
    response = Tentacat.Organizations.Members.list(client, installation.account.login)
    Mrgr.Github.parse_into(response, Mrgr.Github.User)
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

  defmodule Query do
    use Mrgr.Query
  end
end
