defmodule Mrgr.Schema.UserNotificationPreference do
  use Mrgr.Schema
  use Mrgr.Notification.Event

  @moduledoc """
  One preference per user-installation-event.  Can receive an email, slack message, both, or none.
  """

  schema "user_notification_preferences" do
    field(:event, :string)

    field(:email, :boolean)
    field(:slack, :boolean)

    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  def rt_backfill_for_users do
    Mrgr.User.with_installations()
    |> Enum.map(fn user ->
      Enum.map(user.installations, fn installation ->
        create_for_user_and_installation(user, installation)
      end)
    end)
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:user_id, :installation_id, :event, :email, :slack])
    |> validate_inclusion(:event, @notification_events)
  end

  def create_for_user_and_installation(user, installation) do
    params = %{
      user_id: user.id,
      installation_id: installation.id,
      email: user.notification_email
    }

    %__MODULE__{}
    |> changeset(params)
    |> Mrgr.Repo.insert()
  end
end
