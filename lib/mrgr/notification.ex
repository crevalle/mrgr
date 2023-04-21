defmodule Mrgr.Notification do
  use Mrgr.Notification.Event

  alias __MODULE__.Query

  def rt_seed_event do
    seed_new_event(@pr_controversy, %{email: true})
  end

  def seed_new_event(event_name, opts \\ %{}) do
    Mrgr.Schema.User
    |> Mrgr.User.Query.with_installations()
    |> Mrgr.Repo.all()
    |> Enum.map(fn user ->
      Enum.map(user.installations, fn installation ->
        create_for_user_and_installation(user, installation, event_name, opts)
      end)
    end)
  end

  def create_for_user_and_installation(user, installation, event_name, opts \\ %{}) do
    params =
      %{
        event: event_name,
        user_id: user.id,
        installation_id: installation.id,
        email: false,
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

  defmodule Query do
    use Mrgr.Query

    def for_installation(query, id) do
      from(q in query, where: q.installation_id == ^id)
    end

    def for_event(query, event) do
      from(q in query, where: q.event == ^event)
    end

    def with_user(query) do
      from(q in query, join: u in assoc(q, :user), preload: [user: u])
    end
  end
end
