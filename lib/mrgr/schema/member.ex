defmodule Mrgr.Schema.Member do
  @moduledoc """
  A member is a github user that's tied to an organization
  (and later, maybe specific repos through teams).

  Organizations have members through memberships, and members have many orgs via the same.

  Members are 1-1 with Users.  The two objects are very similar, but we keep them
  distinct in order to distinguish who has created a Mrgr account.  We must still know
  who's a member even though they haven't signed up with us.  Yet :).

  Users may also deactivate their Mrgr account, but they'd still be members in GH.

  Members may not be actual users!  Could be a bot, maybe even an org? Who knows.  Another reason
  we don't automatically use Users.
  """

  use Mrgr.Schema

  # TODO: index on members.login
  #
  schema "members" do
    field(:avatar_url, :string)
    field(:events_url, :string)
    field(:external_id, :integer)
    field(:followers_url, :string)
    field(:following_url, :string)
    field(:gists_url, :string)
    field(:gravatar_id, :string)
    field(:html_url, :string)
    field(:login, :string)
    field(:node_id, :string)
    field(:organizations_url, :string)
    field(:received_events_url, :string)
    field(:repos_url, :string)
    field(:site_admin, :boolean)
    field(:starred_url, :string)
    field(:subscriptions_url, :string)
    field(:type, :string)
    field(:url, :string)

    timestamps()

    belongs_to(:user, Mrgr.Schema.User)

    # TODO: _active_ memberships, where a user leaves the company but still has records of approvals
    has_many(:memberships, Mrgr.Schema.Membership)
    has_many(:installations, through: [:memberships, :installation])
  end

  @allowed ~w[
    avatar_url
    events_url
    external_id
    followers_url
    following_url
    gists_url
    gravatar_id
    html_url
    login
    node_id
    organizations_url
    received_events_url
    repos_url
    site_admin
    starred_url
    subscriptions_url
    type
    url
    user_id
  ]a

  def changeset(%Mrgr.Github.User{} = user) do
    user
    |> Map.from_struct()
    |> changeset()
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @allowed)
    |> foreign_key_constraint(:user_id)
  end
end
