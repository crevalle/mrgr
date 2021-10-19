defmodule Mrgr.Installation do
  def create_from_webhook(payload) do
    repository_params = payload["repositories"]

    sender = Mrgr.Github.User.new(payload["sender"])

    creator = Mrgr.User.find(sender)

    {:ok, installation} =
      payload
      |> Map.get("installation")
      |> Map.merge(%{"creator_id" => creator.id, "repositories" => repository_params})
      |> Mrgr.Schema.Installation.create_changeset()
      |> Mrgr.Repo.insert()

    # TODO: tokens
    %{token: token} = Mrgr.Installation.create_access_token(installation)

    # {:ok, installation, token}

    # create memberships
    members = fetch_members(installation, client)
    add_team_members(installation, members)

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

  def find_or_create_access_token(installation) do
  end

  def create_access_token(%{external_id: id} = _installation) do
    token = Mrgr.Github.JwtToken.signed_jwt()

    client = Tentacat.Client.new(%{jwt: token})
    response = Tentacat.App.Installations.token(client, id)
    Mrgr.Github.parse_into(response, Mrgr.Github.AccessToken)
  end

  # assumes account has been preloaded
  # and install access token has been generated
  # later, find or create a token ..?
  # should we pass an account in, rather than an install?  what's the controlling entity?
  def fetch_members(installation, token) do
    client = Tentacat.Client.new(%{access_token: token})
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
end
