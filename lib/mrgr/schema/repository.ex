defmodule Mrgr.Schema.Repository do
  use Mrgr.Schema

  schema "repositories" do
    field(:data, :map)
    # this can go vvv
    field(:external_id, :integer)
    field(:full_name, :string)
    field(:language, :string)
    field(:name, :string)
    field(:node_id, :string)
    field(:private, :boolean)
    field(:merge_freeze_enabled, :boolean, default: false)

    embeds_one(:settings, Mrgr.Schema.RepositorySettings, on_replace: :update)
    embeds_one(:parent, Mrgr.Schema.Repository.Parent, on_replace: :delete)

    belongs_to(:installation, Mrgr.Schema.Installation)

    belongs_to(:policy, Mrgr.Schema.RepositorySettingsPolicy,
      foreign_key: :repository_settings_policy_id
    )

    has_many(:members, through: [:installation, :member])
    has_many(:users, through: [:installation, :users])

    has_many(:pull_requests, Mrgr.Schema.PullRequest, on_delete: :delete_all)

    has_many(:file_change_alerts, Mrgr.Schema.FileChangeAlert, on_delete: :delete_all)

    timestamps()
  end

  @allowed ~w[
    full_name
    language
    name
    node_id
    private
    installation_id
    repository_settings_policy_id
  ]a

  def basic_changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> foreign_key_constraint(:installation_id)
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

  def changeset(schema, params) do
    schema
    |> cast(params, @allowed)
    |> foreign_key_constraint(:installation_id)
    |> foreign_key_constraint(:repository_settings_policy_id)
    |> cast_embed(:settings)
    |> cast_embed(:parent)
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

  def policy_name(%{policy: %{name: name}}), do: name
  def policy_name(_repo), do: nil

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
