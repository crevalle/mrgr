defmodule Mrgr.Schema.Merge do
  use Mrgr.Schema

  schema "merges" do
    field(:external_id, :integer)
    field(:number, :integer)
    field(:opened_at, :utc_datetime)
    field(:status, :string)
    field(:title, :string)
    field(:url, :string)
    field(:merge_queue_index, :integer)
    field(:raw, :map)

    embeds_one(:user, Mrgr.Github.User, on_replace: :update)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    embeds_one(:merged_by, Mrgr.Github.User, on_replace: :update)
    field(:merged_at, :utc_datetime)

    timestamps()
  end

  @create_fields ~w[
    number
    opened_at
    title
    url
    repository_id
    merge_queue_index
    raw
  ]a

  @synchronize_fields ~w[
    title
    raw
  ]a

  def create_changeset(schema, params) do
    params = set_opened_at(params)

    schema
    |> cast(params, @create_fields)
    |> cast_embed(:user)
    |> cast_embed(:head)
    |> put_open_status()
    |> put_external_id()
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def merge_queue_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:merge_queue_index])
  end

  def synchronize_changeset(schema, %{"pull_request" => params}) do
    schema
    |> cast(params, @synchronize_fields)
    |> cast_embed(:head)
  end

  def close_changeset(schema, %{"merged" => true} = params) do
    schema
    |> cast(params, [])
    |> cast_embed(:merged_by)
    |> put_closed_status()
    |> put_timestamp(:merged_at)
  end

  def close_changeset(schema, %{"merged" => false} = params) do
    schema
    |> cast(params, [])
    |> put_closed_status()
  end

  def put_closed_status(changeset) do
    put_change(changeset, :status, "closed")
  end

  def put_open_status(changeset) do
    case get_change(changeset, :status) do
      empty when empty in [nil, ""] ->
        put_change(changeset, :status, "open")

      _status ->
        changeset
    end
  end

  def set_opened_at(%{:created_at => at} = params) do
    Map.put(params, :opened_at, at)
  end

  def set_opened_at(%{"created_at" => at} = params) do
    Map.put(params, "opened_at", at)
  end
end
