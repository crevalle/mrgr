defmodule Mrgr.Schema.Repository do
  use Mrgr.Schema

  schema "repositories" do
    field(:data, :map)
    field(:external_id, :integer)
    field(:full_name, :string)
    field(:language, :string)
    field(:name, :string)
    field(:node_id, :string)
    field(:private, :boolean)
    field(:merge_freeze_enabled, :boolean, default: false)

    embeds_one(:settings, Mrgr.Schema.RepositorySecuritySettings, on_replace: :delete)
    embeds_one(:parent, Mrgr.Schema.Repository.Parent, on_replace: :delete)

    field(:dismiss_stale_reviews, :boolean, read_after_writes: true)
    field(:require_code_owner_reviews, :boolean, read_after_writes: true)
    field(:required_approving_review_count, :integer, read_after_writes: true)

    belongs_to(:installation, Mrgr.Schema.Installation)
    has_many(:members, through: [:installation, :member])
    has_many(:users, through: [:installation, :users])

    has_many(:pull_requests, Mrgr.Schema.PullRequest)

    has_many(:file_change_alerts, Mrgr.Schema.FileChangeAlert, on_delete: :delete_all)

    timestamps()
  end

  @allowed ~w[
    full_name
    language
    name
    node_id
    private
    external_id
    installation_id
  ]a

  def changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> foreign_key_constraint(:installation_id)
    |> put_external_id()
    |> put_data_map()
  end

  def create_pull_requests_changeset(schema, params) do
    schema
    |> Mrgr.Repo.preload(:pull_requests)
    |> cast(params, [])
    |> cast_assoc(:pull_requests, with: &Mrgr.Schema.PullRequest.create_changeset/2)
  end

  def merge_freeze_changeset(schema, attrs) do
    schema
    |> cast(attrs, [:merge_freeze_enabled])
  end

  def branch_protection_changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :dismiss_stale_reviews,
      :require_code_owner_reviews,
      :required_approving_review_count
    ])
  end

  def settings_changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:settings)
  end

  def parent_changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:parent)
  end

  def owner_name(%{full_name: full_name}) do
    full_name
    |> String.split("/")
    |> List.to_tuple()
  end

  def main_branch(%{data: %{"default_branch" => branch}}), do: branch
  def main_branch(_repo), do: "master"

  # %{
  #   "full_name" => "crevalle/node-cql-binary",
  #   "id" => 8829819,
  #   "name" => "node-cql-binary",
  #   "node_id" => "MDEwOlJlcG9zaXRvcnk4ODI5ODE5",
  #   "private" => false
  # },

  defmodule Parent do
    use Mrgr.Schema

    @primary_key false
    embedded_schema do
      field(:node_id, :string)
      field(:name, :string)
      field(:name_with_owner, :string)
    end

    def changeset(schema, params) do
      schema
      |> cast(params, [:node_id, :name, :name_with_owner])
    end
  end
end
