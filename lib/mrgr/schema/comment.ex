defmodule Mrgr.Schema.Comment do
  use Mrgr.Schema

  schema "comments" do
    field(:object, Ecto.Enum, values: [:issue_comment, :pull_request_review_comment])
    field(:posted_at, :utc_datetime)
    field(:raw, :map)

    belongs_to(:pull_request, Mrgr.Schema.PullRequest)

    timestamps()
  end

  def create_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:object, :raw, :pull_request_id, :posted_at])
    |> validate_required([:object, :posted_at])
    |> foreign_key_constraint(:pull_request_id)
  end
end
