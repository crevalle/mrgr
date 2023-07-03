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

    embeds_one :settings, Settings, on_replace: :update do
      field :big_pr_threshold, :integer
    end

    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  def rt_set_settings do
    Mrgr.Notification.preferences_for_event(@big_pr)
    |> Enum.map(fn preference ->
      preference
      |> settings_changeset(%{settings: %{big_pr_threshold: 1000}})
      |> Mrgr.Repo.update!()
    end)
  end

  def settings_changeset(schema, params) do
    schema
    |> cast(params, [])
    |> cast_embed(:settings, with: &the_settings_changeset/2)
  end

  def the_settings_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:big_pr_threshold])
    |> validate_number(:big_pr_threshold, greater_than: 0)
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
