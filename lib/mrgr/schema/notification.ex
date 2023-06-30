defmodule Mrgr.Schema.Notification do
  use Mrgr.Schema

  @channels ["slack", "email"]

  schema "notifications" do
    field(:channel, :string)
    field(:type, :string)
    field(:error, :string)

    belongs_to(:user, Mrgr.Schema.User, foreign_key: :recipient_id)

    has_many(:notifications_pull_requests, Mrgr.Schema.NotificationPullRequest)
    has_many(:pull_requests, through: [:notifications_pull_requests, :pull_request])

    timestamps()
  end

  @fields ~w(channel type error recipient_id)a

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @fields)
    |> validate_inclusion(:channel, @channels)
    |> foreign_key_constraint(:recipient_id)
  end
end
