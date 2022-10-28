defmodule Mrgr.Schema.PRReview do
  use Mrgr.Schema

  schema "pr_reviews" do
    field(:state, :string)
    field(:node_id, :string)
    field(:commit_id, :string)
    field(:submitted_at, :utc_datetime)
    field(:data, :map)

    belongs_to(:merge, Mrgr.Schema.Merge)
    embeds_one(:user, Mrgr.Github.User)

    timestamps()
  end

  @create_params ~w(
    commit_id
    data
    merge_id
    node_id
    state
    submitted_at
  )a

  def create_changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @create_params)
    |> put_data_map()
    |> cast_embed(:user)
    |> validate_required(@create_params)
    |> foreign_key_constraint(:merge_id)
  end
end