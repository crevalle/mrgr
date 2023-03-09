defmodule Mrgr.Schema.UserSnoozedPullRequest do
  use Mrgr.Schema

  schema "user_snoozed_pull_requests" do
    field(:snoozed_until, :utc_datetime)

    belongs_to(:pull_request, Mrgr.Schema.PullRequest)
    belongs_to(:user, Mrgr.Schema.User)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:user_id, :pull_request_id, :snoozed_until])
    |> validate_required([:user_id, :pull_request_id, :snoozed_until])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:pull_request_id)
  end
end
