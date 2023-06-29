defmodule Mrgr.Notification do
  use Mrgr.Notification.Event
  alias __MODULE__.Query

  alias Mrgr.Schema.Notification, as: Schema
  alias Mrgr.Schema.UserNotificationPreference, as: Preference

  @typep preference :: Preference.t()
  @type notifiable ::
          preference() | Mrgr.Schema.HighImpactFileRule.t()

  @typep preference_bucket :: %{email: [preference()], slack: [preference()]}
  @typep user_bucket :: %{email: [Mrgr.Schema.User.t()], slack: [Mrgr.Schema.User.t()]}

  # lists of emails and slack messages
  @type result :: %{email: list(), slack: list()}

  @spec create(integer(), tuple(), String.t(), String.t()) :: Schema.t()
  def create(recipient_id, res, channel, type) do
    attrs = %{
      recipient_id: recipient_id,
      channel: channel,
      type: type
    }

    attrs = put_error(res, attrs)

    %Schema{}
    |> Schema.changeset(attrs)
    |> Mrgr.Repo.insert!()
  end

  # for slack only - emails will always assume to go through ok
  def put_error({:error, reason}, attrs) do
    Map.put(attrs, :error, inspect(reason))
  end

  def put_error(_success, attrs), do: attrs

  def create_default_preferences_for_installation(%Mrgr.Schema.Installation{} = installation) do
    # when an installation is created the only user is its creator
    Enum.map(@notification_events, fn event ->
      create_preference(event, installation.creator_id, installation.id)
    end)
  end

  def create_default_preferences_for_user(user) do
    user = Mrgr.Repo.preload(user, :installations)

    Enum.map(@notification_events, fn event ->
      Enum.map(user.installations, fn installation ->
        create_preference(event, user.id, installation.id)
      end)
    end)
  end

  def rt_seed_event do
    seed_new_event(@big_pr)
  end

  def seed_new_event(event, opts \\ %{}) do
    users = Mrgr.User.with_installations()

    Enum.map(users, fn user ->
      Enum.map(user.installations, fn installation ->
        create_preference(event, user.id, installation.id, opts)
      end)
    end)
  end

  def create_preference(event, user_id, installation_id, opts \\ %{}) do
    params =
      %{
        event: event,
        user_id: user_id,
        installation_id: installation_id,
        email: true,
        slack: false
      }
      |> Map.merge(opts)

    %Preference{}
    |> Preference.changeset(params)
    |> Mrgr.Repo.insert()
  end

  @doc """
  returns the users at a PR's installation who've set at least one channel for this event
  """
  def consumers_of_event(event, %Mrgr.Schema.PullRequest{} = pull_request) do
    consumers_of_event(event, pull_request.repository.installation_id)
  end

  def consumers_of_event(event, installation_id) do
    preferences = fetch_preferences_at_installation(installation_id, event)

    preferences
    |> bucketize_preferences()
    |> preference_bucket_to_user_bucket()
  end

  @doc "converts a bucket of preferences to a bucket of those preferences' users"
  @spec preference_bucket_to_user_bucket(preference_bucket()) :: user_bucket()
  def preference_bucket_to_user_bucket(preferences_by_channel) do
    preferences_by_channel
    |> Enum.reduce(%{}, fn {channel, prefs}, acc ->
      Map.put(acc, channel, Enum.map(prefs, & &1.user))
    end)
  end

  @spec bucketize_preferences(list()) :: preference_bucket()
  def bucketize_preferences(preferences) do
    Enum.reduce(preferences, %{email: [], slack: []}, fn preference, acc ->
      # strips out rules that have no channels
      acc
      |> put_email_channel(preference)
      |> put_slack_channel(preference)
    end)
  end

  def put_email_channel(acc, %{email: true} = rule) do
    rules = acc.email
    Map.put(acc, :email, [rule | rules])
  end

  def put_email_channel(acc, _rule), do: acc

  def put_slack_channel(acc, %{slack: true} = rule) do
    rules = acc.slack
    Map.put(acc, :slack, [rule | rules])
  end

  def put_slack_channel(acc, _rule), do: acc

  def fetch_preferences_at_installation(installation_id, event) do
    Preference
    |> Query.for_installation(installation_id)
    |> Query.for_event(event)
    |> Query.with_user()
    |> Mrgr.Repo.all()
  end

  @doc "converts all email notifications to slack"
  def enable_slack_notifications(user, installation) do
    preferences =
      Preference
      |> Query.for_installation(installation.id)
      |> Query.for_user(user.id)
      |> Mrgr.Repo.all()
      |> Enum.map(&convert_to_slack/1)

    hifs =
      Mrgr.HighImpactFileRule.for_user_at_installation(user.id, installation.id)
      |> Enum.map(&convert_to_slack/1)

    %{preferences: preferences, hifs: hifs}
  end

  def disable_slack_notifications(user, installation) do
    preferences =
      Preference
      |> Query.for_installation(installation.id)
      |> Query.for_user(user.id)
      |> Mrgr.Repo.all()
      |> Enum.map(&convert_from_slack/1)

    hifs =
      Mrgr.HighImpactFileRule.for_user_at_installation(user.id, installation.id)
      |> Enum.map(&convert_from_slack/1)

    %{preferences: preferences, hifs: hifs}
  end

  def convert_to_slack(%{email: false} = notifiable), do: notifiable

  def convert_to_slack(%{email: true} = notifiable) do
    notifiable
    |> enable_slack()
    |> disable_email()
  end

  def convert_from_slack(%{slack: false} = notifiable), do: notifiable

  def convert_from_slack(%{slack: true} = notifiable) do
    notifiable
    |> disable_slack()
    |> enable_email()
  end

  @spec enable_slack(notifiable()) :: notifiable()
  def enable_slack(notifiable) do
    notifiable
    |> Ecto.Changeset.change(%{slack: true})
    |> Mrgr.Repo.update!()
  end

  @spec disable_slack(notifiable()) :: notifiable()
  def disable_slack(notifiable) do
    notifiable
    |> Ecto.Changeset.change(%{slack: false})
    |> Mrgr.Repo.update!()
  end

  @spec enable_email(notifiable()) :: notifiable()
  def enable_email(notifiable) do
    notifiable
    |> Ecto.Changeset.change(%{email: true})
    |> Mrgr.Repo.update!()
  end

  @spec disable_email(notifiable()) :: notifiable()
  def disable_email(notifiable) do
    notifiable
    |> Ecto.Changeset.change(%{email: false})
    |> Mrgr.Repo.update!()
  end

  ### QUERIES

  def paged_for_user(id, params \\ %{}) do
    Schema
    |> Query.for_recipient(id)
    |> Query.rev_cron()
    |> Mrgr.Repo.paginate(params)
  end

  defmodule Query do
    use Mrgr.Query

    def for_recipient(query, id) do
      from(q in query,
        where: q.recipient_id == ^id
      )
    end

    def for_user(query, id) do
      from(q in query,
        where: q.user_id == ^id
      )
    end

    def for_installation(query, id) do
      from(q in query,
        where: q.installation_id == ^id
      )
    end

    def for_event(query, event) do
      from(q in query,
        where: q.event == ^event
      )
    end

    def with_user(query) do
      from(q in query,
        join: u in assoc(q, :user),
        join: i in assoc(u, :current_installation),
        preload: [user: {u, current_installation: i}]
      )
    end
  end
end
