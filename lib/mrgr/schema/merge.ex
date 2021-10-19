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

  def create_changeset(schema, params) do
    schema
    |> cast(params, @create_fields)
    |> cast_embed(:user)
    |> put_open_status()
    |> put_external_id()
    |> put_opened_at()
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:author_id)
  end

  def put_open_status(changeset) do
    case get_change(changeset, :status) do
      empty when empty in [nil, ""] ->
        put_change(changeset, :status, "open")

      _status ->
        changeset
    end
  end

  def put_opened_at(changeset) do
    case get_change(changeset, :opened_at) do
      nil ->
        opened = changeset.params.created_at
        put_change(changeset, :opened_at, opened)

      _opened ->
        changeset
    end
  end
end
