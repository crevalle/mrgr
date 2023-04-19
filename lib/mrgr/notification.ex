defmodule Mrgr.Notification do
  use Mrgr.Notification.Event

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
end
