defmodule Mrgr.Schema.UserNotificationAddress do
  use Mrgr.Schema

  @moduledoc """
  A user may want to get notifications at different email addresses based on the installation.

  Also, users at different Slack workspaces will have different user ids.
  """

  schema "user_notification_addresses" do
    field(:email, :string)
    field(:slack_id, :string)

    belongs_to(:user, Mrgr.Schema.User)
    belongs_to(:installation, Mrgr.Schema.Installation)

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:user_id, :installation_id, :email, :slack_id])
    |> validate_required(:email)
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
