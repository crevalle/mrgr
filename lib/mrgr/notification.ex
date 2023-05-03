defmodule Mrgr.Notification do
  use Mrgr.Notification.Event

  alias __MODULE__.Query

  @type notifiable ::
          Mrgr.Schema.UserNotificationPreference.t() | Mrgr.Schema.HighImpactFileRule.t()

  def create_defaults_for_new_installation(%Mrgr.Schema.Installation{} = installation) do
    # when an installation is created the only user is its creator
    Enum.map(@notification_events, fn event ->
      create_for_user_and_installation(event, installation.creator_id, installation.id)
    end)
  end

  def create_defaults_for_user(user) do
    user = Mrgr.Repo.preload(user, :installations)

    Enum.map(@notification_events, fn event ->
      Enum.map(user.installations, fn installation ->
        create_for_user_and_installation(event, user.id, installation.id)
      end)
    end)
  end

  def rt_seed_event do
    seed_new_event(@pr_controversy)
  end

  def seed_new_event(event, opts \\ %{}) do
    users =
      Mrgr.Schema.User
      |> Mrgr.User.Query.with_installations()
      |> Mrgr.Repo.all()

    Enum.map(users, fn user ->
      Enum.map(user.installations, fn installation ->
        create_for_user_and_installation(event, user.id, installation.id, opts)
      end)
    end)
  end

  def create_for_user_and_installation(event, user_id, installation_id, opts \\ %{}) do
    params =
      %{
        event: event,
        user_id: user_id,
        installation_id: installation_id,
        email: true,
        slack: false
      }
      |> Map.merge(opts)

    %Mrgr.Schema.UserNotificationPreference{}
    |> Mrgr.Schema.UserNotificationPreference.changeset(params)
    |> Mrgr.Repo.insert()
  end

  def consumers_of_event(event, pull_request) do
    preferences =
      fetch_preferences_at_installation(pull_request.repository.installation_id, event)

    preferences
    |> bucketize_preferences()
    |> return_users()
  end

  def return_users(preferences_by_channel) do
    preferences_by_channel
    |> Enum.reduce(%{}, fn {channel, prefs}, acc ->
      Map.put(acc, channel, Enum.map(prefs, & &1.user))
    end)
  end

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
    Mrgr.Schema.UserNotificationPreference
    |> Query.for_installation(installation_id)
    |> Query.for_event(event)
    |> Query.with_user()
    |> Mrgr.Repo.all()
  end

  def enable_slack_notifications(user, installation) do
    preferences =
      Mrgr.Schema.UserNotificationPreference
      |> Query.for_installation(installation.id)
      |> Query.for_user(user.id)
      |> Mrgr.Repo.all()
      |> Enum.map(&enable_slack/1)

    hifs =
      Mrgr.HighImpactFileRule.for_user_at_installation(user.id, installation.id)
      |> Enum.map(&enable_slack/1)

    %{preferences: preferences, hifs: hifs}
  end

  def disable_slack_notifications(user, installation) do
    preferences =
      Mrgr.Schema.UserNotificationPreference
      |> Query.for_installation(installation.id)
      |> Query.for_user(user.id)
      |> Mrgr.Repo.all()
      |> Enum.map(&disable_slack/1)

    hifs =
      Mrgr.HighImpactFileRule.for_user_at_installation(user.id, installation.id)
      |> Enum.map(&disable_slack/1)

    %{preferences: preferences, hifs: hifs}
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

  defmodule Query do
    use Mrgr.Query

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
