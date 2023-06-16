defmodule Mrgr.Schema.User do
  use Mrgr.Schema

  @derive {Swoosh.Email.Recipient, name: :name, address: :notification_email}

  schema "users" do
    field(:avatar_url, :string)
    field(:birthday, :string)
    field(:description, :string)
    field(:email, :string)
    field(:first_name, :string)
    field(:image, :string)
    field(:installing_slackbot_from_profile_page, :boolean)
    field(:last_name, :string)
    field(:last_seen_at, :utc_datetime)
    field(:location, :string)
    field(:name, :string)
    field(:nickname, :string)
    # the same node_id as the member
    field(:node_id, :string)
    field(:notification_email, :string)
    field(:phone, :string)
    field(:refresh_token, :string)
    field(:send_weekly_changelog_email, :boolean)
    field(:timezone, :string)
    field(:token, :string)
    field(:token_expires_at, :utc_datetime)
    field(:token_updated_at, :utc_datetime)

    has_one(:member, Mrgr.Schema.Member)
    has_many(:memberships, through: [:member, :memberships])
    has_many(:installations, through: [:memberships, :installation])
    has_many(:repositories, through: [:installations, :repositories])

    has_many(:user_visible_repositories, Mrgr.Schema.UserVisibleRepository)
    has_many(:visible_repositories, through: [:user_visible_repositories, :repository])

    has_many(:user_snoozed_pull_requests, Mrgr.Schema.UserSnoozedPullRequest)
    has_many(:snoozed_pull_requests, through: [:user_snoozed_pull_requests, :pull_request])

    has_many(:notification_addresses, Mrgr.Schema.UserNotificationAddress)
    has_many(:notification_preferences, Mrgr.Schema.UserNotificationPreference)

    has_many(:notifications, Mrgr.Schema.Notification, foreign_key: :recipient_id)

    # across installations
    has_many(:pr_tabs, Mrgr.Schema.PRTab)

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
    avatar_url
    birthday
    description
    email
    first_name
    image
    last_name
    location
    name
    nickname
    node_id
    notification_email
    phone
  ]a

  @welcome_back_params ~w[
    avatar_url
    first_name
    last_name
    name
    nickname
    node_id
    image
    location
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
    |> accept_login_param()
    |> set_default_notification_email()
    |> tokens_changeset(params)
    |> cast_embed(:urls, with: &url_changeset/2)
  end

  def email_changeset(schema, params) do
    schema
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^\S+@\S+\.\S+$/)
    |> set_default_notification_email()
  end

  def welcome_back_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @welcome_back_params)
  end

  def url_changeset(schema, params) do
    schema
    |> cast(params, @urls)
  end

  def tokens_changeset(schema, params) do
    schema
    |> cast(params, @tokens)
    |> put_timestamp(:token_updated_at)
    |> validate_required([:token])
  end

  def current_installation_changeset(schema, params) do
    schema
    |> cast(params, [:current_installation_id])
    |> foreign_key_constraint(:current_installation_id)
  end

  def seen_changeset(schema) do
    schema
    |> change()
    |> put_timestamp(:last_seen_at)
  end

  def notification_changeset(schema, params) do
    schema
    |> cast(params, [:notification_email])
    |> validate_required(:notification_email)
  end

  def weekly_changelog_changeset(schema, params) do
    schema
    |> cast(params, [:send_weekly_changelog_email])
  end

  def timezone_changeset(schema, params) do
    schema
    |> cast(params, [:timezone])
  end

  def image(%{avatar_url: url}) when is_bitstring(url), do: url
  def image(%{image: url}) when is_bitstring(url), do: url
  def image(_gee_i_dunno), do: ""

  defp accept_login_param(changeset) do
    # the initial oauth params uses a "login" attribute instead of "nickname" like everywhere else
    with nil <- get_change(changeset, :nickname),
         nickname when is_bitstring(nickname) <- changeset.params["login"] do
      put_change(changeset, :nickname, changeset.params["login"])
    else
      _got_nickname ->
        changeset
    end
  end

  defp set_default_notification_email(changeset) do
    case get_change(changeset, :notification_email) do
      nil ->
        email = get_change(changeset, :email)
        put_change(changeset, :notification_email, email)

      _set ->
        changeset
    end
  end

  def is_github_user?(%{nickname: nick}, %{login: nick}), do: true
  def is_github_user?(_user, _gh_user), do: false

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
