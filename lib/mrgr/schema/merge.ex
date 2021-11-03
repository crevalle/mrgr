defmodule Mrgr.Schema.Merge do
  use Mrgr.Schema

  schema "merges" do
    field(:external_id, :integer)
    field(:number, :integer)
    field(:opened_at, :utc_datetime)
    field(:status, :string)
    field(:title, :string)
    field(:url, :string)

    embeds_one(:user, Mrgr.Github.User)

    embeds_one(:head, Mrgr.Schema.Head, on_replace: :update)

    belongs_to(:repository, Mrgr.Schema.Repository)
    belongs_to(:author, Mrgr.Schema.Member)

    belongs_to(:merged_by, Mrgr.Schema.Member)
    field(:merged_at, :utc_datetime)

    timestamps()
  end

  @create_fields ~w[
    number
    opened_at
    title
    url
  ]a

  @synchronize_fields ~w[
    title
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

  def synchronize_changeset(schema, %{"pull_request" => params}) do
    schema
    |> cast(params, @synchronize_fields)
    |> cast_embed(:head)
  end

  def merge_changeset(schema, params) do
    schema
    |> cast(params, [:merged_by_id])
    |> foreign_key_constraint(:merged_by_id)
    |> put_merged_status()
    |> put_merged_at()
  end

  def put_merged_status(changeset) do
    put_change(changeset, :status, "merged")
  end

  def put_merged_at(changeset) do
    put_change(changeset, :merged_at, DateTime.utc_now())
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
