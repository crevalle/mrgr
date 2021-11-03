defmodule Mrgr.Schema.User do
  use Mrgr.Schema

  schema "users" do
    field(:birthday, :string)
    field(:description, :string)
    field(:email, :string)
    field(:first_name, :string)
    field(:image, :string)
    field(:last_name, :string)
    field(:location, :string)
    field(:name, :string)
    field(:nickname, :string)
    field(:phone, :string)
    field(:provider, :string)
    field(:refresh_token, :string)
    field(:token, :string)
    field(:token_expires_at, :utc_datetime)
    field(:token_updated_at, :utc_datetime)

    has_one(:member, Mrgr.Schema.Member)
    has_many(:memberships, through: [:member, :memberships])
    has_many(:installations, through: [:memberships, :installation])
    has_many(:repositories, through: [:installations, :repositories])

    belongs_to(:current_installation, Mrgr.Schema.Installation)

    embeds_one :urls, Urls do
      field(:api_url, :string)
      field(:avatar_url, :string)
      field(:blog, :string)
      field(:events_url, :string)
      field(:followers_url, :string)
      field(:following_url, :string)
      field(:gists_url, :string)
      field(:html_url, :string)
      field(:organizations_url, :string)
      field(:received_events_url, :string)
      field(:repos_url, :string)
      field(:starred_url, :string)
      field(:subscriptions_url, :string)
    end

    timestamps()
  end

  @create_params ~w[
    provider
    birthday
    description
    email
    first_name
    image
    last_name
    location
    name
    nickname
    phone
  ]a

  @tokens ~w[
    token
    refresh_token
    token_expires_at
    token_updated_at
  ]a

  @urls ~w[
    api_url
    avatar_url
    blog
    events_url
    followers_url
    following_url
    gists_url
    html_url
    organizations_url
    received_events_url
    repos_url
    starred_url
    subscriptions_url
  ]a

  def create_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, @create_params)
    |> tokens_changeset(params)
    |> cast_embed(:urls, with: &url_changeset/2)
  end

  def url_changeset(schema, params) do
    schema
    |> cast(params, @urls)
  end

  def tokens_changeset(schema, params) do
    schema
    |> cast(params, @tokens)
    |> set_token_updated_at()
    |> validate_required([:token])
  end

  def current_installation_changeset(schema, params) do
    schema
    |> cast(params, [:current_installation_id])
    |> foreign_key_constraint(:current_installation_id)
  end

  defp set_token_updated_at(changeset) do
    # cast/3 automatically removes microseconds.  need to explicity
    # do this when calling put_change/3
    # https://elixirforum.com/t/upgrading-to-ecto-3-anyway-to-easily-deal-with-usec-it-complains-with-or-without-usec/22137/7?u=desmond
    now = DateTime.truncate(DateTime.utc_now(), :second)
    put_change(changeset, :token_updated_at, now)
  end

  # provider: "github",
  # token: "token",
  # refresh_token: "anothr toekn",
  # token_expires_at: integer()

  # birthday: nil,
  # description: "Elixirist, founder of @empexconf, cohost of @ElixirTalk.  Pinball enthusiast.  Currently CTO @pay-it-off ",
  # email: "desmond@crevalle.io",
  # first_name: nil,
  # image: "https://avatars.githubusercontent.com/u/572921?v=4",
  # last_name: nil,
  # location: "Los Angeles",
  # name: "Desmond Bowe",
  # nickname: "desmondmonster",
  # phone: nil,
  # urls: %{
  # api_url: "https://api.github.com/users/desmondmonster",
  # avatar_url: "https://avatars.githubusercontent.com/u/572921?v=4",
  # blog: "http://crevalle.io",
  # events_url: "https://api.github.com/users/desmondmonster/events{/privacy}",
  # followers_url: "https://api.github.com/users/desmondmonster/followers",
  # following_url: "https://api.github.com/users/desmondmonster/following{/other_user}",
  # gists_url: "https://api.github.com/users/desmondmonster/gists{/gist_id}",
  # html_url: "https://github.com/desmondmonster",
  # organizations_url: "https://api.github.com/users/desmondmonster/orgs",
  # received_events_url: "https://api.github.com/users/desmondmonster/received_events",
  # repos_url: "https://api.github.com/users/desmondmonster/repos",
  # starred_url: "https://api.github.com/users/desmondmonster/starred{/owner}{/repo}",
  # subscriptions_url: "https://api.github.com/users/desmondmonster/subscriptions"
  # }
  # },
end
