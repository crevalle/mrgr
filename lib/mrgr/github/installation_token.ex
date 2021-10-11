# sample code taken from https://dev.to/etiennedepaulis/github-app-authentication-strategies-with-elixir-4e6

# defmodule Github.InstallationToken do
# import Ecto.Query, warn: false
# alias MyApplication.Repo

# use Ecto.Schema
# import Ecto.Changeset

# alias Github.InstallationToken

# schema "installation_tokens" do
# field :expires_at, :utc_datetime
# field :token, :string
# field :organization, :string

# timestamps()
# end

# @doc false
# def changeset(installation_token, attrs) do
# installation_token
# |> cast(attrs, [:token, :organization, :expires_at])
# |> validate_required([:token, :organization, :expires_at])
# end

# def create_installation_token(attrs \\ %{}) do
# %InstallationToken{}
# |> InstallationToken.changeset(attrs)
# |> Repo.insert()
# end

# def valid_token_for(organization) do
# installation_token = find_or_create_installation_token(organization)

# installation_token.token
# end

# defp find_installation_id(client, organization) do
# {200, installations, _response} = Tentacat.App.Installations.list_mine(client)

# matched_installation = Enum.find(installations, fn installation -> installation["account"]["login"] == organization end)

# matched_installation["id"]
# end

# defp generate_installation_token(organization) do
# jwt = Github.JwtToken.signed_jwt
# client = Tentacat.Client.new(%{jwt: jwt})

# installation_id = find_installation_id(client, organization)

# {201, access_tokens, _response} = Tentacat.App.Installations.token(client, installation_id)

# %{token: access_tokens["token"], expires_at: access_tokens["expires_at"], organization: organization}
# end

# defp find_or_create_installation_token(organization) do
# current_datetime = DateTime.utc_now()

# query = from i in InstallationToken, where: ^current_datetime < i.expires_at and i.organization == ^organization

# query |> first |> Repo.one |> eventually_create_installation_token(organization)
# end

# defp eventually_create_installation_token(nil, organization) do
# {:ok, installation_token} = generate_installation_token(organization) |> create_installation_token

# installation_token
# end

# defp eventually_create_installation_token(installation_token = %InstallationToken{}, _organization) do
# installation_token
# end
# end
