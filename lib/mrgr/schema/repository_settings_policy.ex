defmodule Mrgr.Schema.RepositorySettingsPolicy do
  use Mrgr.Schema

  schema "repository_settings_policies" do
    field(:name, :string)
    field(:default, :boolean)

    belongs_to(:installation, Mrgr.Schema.Installation)

    has_many(:repositories, Mrgr.Schema.Repository)

    embeds_one(:settings, Mrgr.Schema.RepositorySettings, on_replace: :delete)

    timestamps()
  end

  def changeset(schema, params \\ %{}) do
    schema
    |> cast(params, [:name, :default, :installation_id])
    |> validate_required([:name, :default, :installation_id])
    |> cast_embed(:settings)
    |> foreign_key_constraint(:installation_id)
  end
end
