defmodule Mrgr.Schema.NotificationPullRequest do
  use Mrgr.Schema

  schema "notifications_pull_requests" do
    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    belongs_to(:notification, Mrgr.Schema.Notification)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:pull_request_id, :notification_id])
    |> foreign_key_constraint(:pull_request_id)
    |> foreign_key_constraint(:notification_id)
  end
end
