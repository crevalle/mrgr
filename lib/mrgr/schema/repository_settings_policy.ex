defmodule Mrgr.Schema.RepositorySettingsPolicy do
  use Mrgr.Schema

  schema "repository_settings_policies" do
    field(:name, :string)
    field(:default, :boolean)
    field(:enforce_automatically, :boolean, default: true)

    belongs_to(:installation, Mrgr.Schema.Installation)

    has_many(:repositories, Mrgr.Schema.Repository)

    embeds_one(:settings, Mrgr.Schema.RepositorySettings, on_replace: :delete)

    timestamps()
  end

  @attrs [:name, :default, :enforce_automatically, :installation_id]
  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, @attrs)
    |> validate_required(@attrs)
    |> cast_embed(:settings)
    |> foreign_key_constraint(:installation_id)
  end
end
